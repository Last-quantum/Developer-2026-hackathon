import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/models/study_day.dart';
import '../domain/models/study_plan.dart';
import '../domain/models/study_week.dart';

/// 本地持久化存储服务，基于 Hive
class LocalStorageService {
  static const String _plansBoxName = 'plans';
  static const String _settingsBoxName = 'settings';
  static const String _lastPlanIdKey = 'lastOpenPlanId';

  late Box<StudyPlan> _plansBox;
  late Box<String> _settingsBox;

  /// 初始化 Hive，注册适配器，打开 Box
  Future<void> init() async {
    if (kIsWeb) {
      // Web 端：Hive 使用 IndexedDB，不需要文件路径
      await Hive.initFlutter();
      debugPrint('📦 Hive storage: IndexedDB (web)');
    } else {
      // 桌面/移动端：显式指定文件目录
      final appDir = await getApplicationDocumentsDirectory();
      final hivePath = '${appDir.path}/career_app_hive';
      debugPrint('📦 Hive storage path: $hivePath');
      Hive.init(hivePath);
    }

    // 注册适配器（顺序无所谓，typeId 不重复即可）
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StudyDayAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StudyWeekAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StudyPlanAdapter());
    }

    _plansBox = await Hive.openBox<StudyPlan>(_plansBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
    debugPrint('📦 Hive initialized: ${_plansBox.length} plans found');
  }

  /// 仅打开 Box（适用于测试，Hive.init 已在外部调用）
  Future<void> initBoxesOnly() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StudyDayAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StudyWeekAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StudyPlanAdapter());
    }
    _plansBox = await Hive.openBox<StudyPlan>(_plansBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  }

  // ───────────────────── Plans CRUD ─────────────────────

  /// 获取所有计划（按创建时间倒序）
  List<StudyPlan> getAllPlans() {
    final plans = _plansBox.values.toList();
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return plans;
  }

  /// 根据 id 获取计划
  StudyPlan? getPlan(String id) {
    try {
      return _plansBox.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 保存计划（新建或更新）
  Future<void> savePlan(StudyPlan plan) async {
    plan.updatedAt = DateTime.now();

    // 找到已有的 key 或用新 key
    final existingKey = _findKeyById(plan.id);
    if (existingKey != null) {
      await _plansBox.put(existingKey, plan);
    } else {
      await _plansBox.add(plan);
    }

    // 同时记住最后打开的计划
    await setLastOpenPlanId(plan.id);
  }

  /// 删除计划
  Future<void> deletePlan(String id) async {
    final key = _findKeyById(id);
    if (key != null) {
      await _plansBox.delete(key);
    }
  }

  int? _findKeyById(String id) {
    for (final entry in _plansBox.toMap().entries) {
      if (entry.value.id == id) return entry.key as int;
    }
    return null;
  }

  // ───────────────────── Settings ─────────────────────

  /// 记住上次打开的计划 id
  Future<void> setLastOpenPlanId(String id) async {
    await _settingsBox.put(_lastPlanIdKey, id);
  }

  /// 获取上次打开的计划 id
  String? getLastOpenPlanId() {
    return _settingsBox.get(_lastPlanIdKey);
  }

  /// 获取上次打开的计划（快捷方法）
  StudyPlan? getLastOpenPlan() {
    final id = getLastOpenPlanId();
    return id != null ? getPlan(id) : null;
  }
}
