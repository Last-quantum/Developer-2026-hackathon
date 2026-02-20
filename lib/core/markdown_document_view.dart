import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Optimized Markdown viewer with LaTeX support and caching
class MarkdownDocumentView extends StatefulWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;

  const MarkdownDocumentView({
    super.key,
    required this.data,
    this.styleSheet,
  });

  @override
  State<MarkdownDocumentView> createState() => _MarkdownDocumentViewState();
}

class _MarkdownDocumentViewState extends State<MarkdownDocumentView>
    with AutomaticKeepAliveClientMixin {
  // Singleton instances to avoid recreating on each build
  static final _inlineSyntaxes = [InlineMathSyntax()];
  static final _blockSyntaxes = [BlockMathSyntax()];
  late final Map<String, MarkdownElementBuilder> _builders;

  @override
  void initState() {
    super.initState();
    _builders = {
      'math': MathBuilder(isBlock: true),
      'inline_math': MathBuilder(isBlock: false),
    };
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SelectionArea(
      child: MarkdownBody(
        data: widget.data,
        selectable: true,
        styleSheet: widget.styleSheet,
        builders: _builders,
        inlineSyntaxes: _inlineSyntaxes,
        blockSyntaxes: _blockSyntaxes,
        extensionSet: md.ExtensionSet.gitHubFlavored,
      ),
    );
  }
}

class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax() : super(r'\$(?!\$)([^\n$]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1);
    if (content == null || content.trim().isEmpty) {
      return false;
    }
    parser.addNode(md.Element.text('inline_math', content));
    return true;
  }
}

class BlockMathSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$');

  @override
  md.Node? parse(md.BlockParser parser) {
    var line = parser.current;
    var working = line.content.substring(2);
    final buffer = StringBuffer();

    final inlineEndIndex = working.indexOf(r'$$');
    if (inlineEndIndex != -1) {
      buffer.write(working.substring(0, inlineEndIndex));
      parser.advance();
      return md.Element.text('math', buffer.toString().trim());
    }

    if (working.trim().isNotEmpty) {
      buffer.writeln(working);
    }
    parser.advance();

    while (!parser.isDone) {
      line = parser.current;
      final endIndex = line.content.indexOf(r'$$');
      if (endIndex != -1) {
        buffer.write(line.content.substring(0, endIndex));
        parser.advance();
        break;
      }
      buffer.writeln(line.content);
      parser.advance();
    }

    return md.Element.text('math', buffer.toString().trim());
  }
}

class MathBuilder extends MarkdownElementBuilder {
  final bool isBlock;
  // Cache for rendered math widgets to avoid re-rendering
  final Map<String, Widget> _cache = {};

  MathBuilder({required this.isBlock});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final content = element.textContent;
    
    // Use cached widget if available
    final cacheKey = '$isBlock:$content';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Render and cache the math widget
    final widget = Math.tex(
      content,
      textStyle: preferredStyle,
      mathStyle: isBlock ? MathStyle.display : MathStyle.text,
      onErrorFallback: (error) {
        // Fallback to plain text on render error
        return Text(
          content,
          style: preferredStyle?.copyWith(
            color: Colors.red.shade700,
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
    
    _cache[cacheKey] = widget;
    return widget;
  }
}
