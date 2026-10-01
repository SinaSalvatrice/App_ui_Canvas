import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class WheelNumberField extends StatefulWidget {
  const WheelNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.min,
    this.max,
    this.step = 1,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final double? min;
  final double? max;
  final double step;

  @override
  State<WheelNumberField> createState() => _WheelNumberFieldState();
}

class _WheelNumberFieldState extends State<WheelNumberField> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant WheelNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != oldWidget.value) {
      _textController.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          isDense: true,
        ),
        onSubmitted: (_) => _commitText(),
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!widget.enabled ||
        !_focusNode.hasFocus ||
        event is! PointerScrollEvent) {
      return;
    }

    final direction = event.scrollDelta.dy < 0 ? 1.0 : -1.0;
    final current = _parse(_textController.text) ?? widget.value;
    final next = _clamp(current + widget.step * direction);
    _textController.text = _format(next);
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
    widget.onChanged(next);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commitText();
  }

  void _commitText() {
    final parsed = _parse(_textController.text);
    if (parsed == null) {
      _textController.text = _format(widget.value);
      return;
    }
    final next = _clamp(parsed);
    _textController.text = _format(next);
    widget.onChanged(next);
  }

  double _clamp(double value) {
    var next = value;
    if (widget.min != null && next < widget.min!) next = widget.min!;
    if (widget.max != null && next > widget.max!) next = widget.max!;
    return next;
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  String _format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
