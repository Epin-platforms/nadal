import 'package:flutter/services.dart';
import '../manager/project/Import_Manager.dart';

class NadalTextField extends StatefulWidget {
  const NadalTextField({super.key, required this.controller, this.node, this.maxLength, this.initText = "",  this.label, this.keyboardType = TextInputType.text, this.onChanged, this.suffixText, this.maxLines, this.isMaxLines = false, this.helper});
  final TextEditingController controller;
  final FocusNode? node;
  final int? maxLength;
  final String initText;
  final String? label;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? suffixText;
  final int? maxLines;
  final bool isMaxLines;
  final String? helper;
  @override
  State<NadalTextField> createState() => _NadalTextFieldState();
}

class _NadalTextFieldState extends State<NadalTextField>{
  bool _valid = true;

  @override
  void initState() {
    widget.controller.text= widget.initText;
    if(widget.maxLength != null){
      widget.controller.addListener(listener);
      _valid = widget.controller.text.length <= widget.maxLength!;
    }
    super.initState();
  }

  @override
  void dispose() {
    if(widget.maxLength != null){
      widget.controller.removeListener(listener);
    }
    super.dispose();
  }

  String? errorText;

  void listener() {
    final textLength = widget.controller.text.length;
    final max = widget.maxLength! + 1;

    if (_valid && textLength >= max || textLength == 0) { //테스트 길이가 넘거나 없을때
      setState(() {
        if(textLength >= max){
          errorText = '너무 길어요! ${widget.maxLength}자 이내로 줄여주세요';
        }else{
          errorText = '입력하지 않으면 다음으로 넘어갈 수 없어요';
        }
        _valid = false;
      });
    }else if(!_valid && textLength <= max){
      setState(() {
        _valid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: false,
      inputFormatters: widget.keyboardType == TextInputType.number ? [
        FilteringTextInputFormatter.digitsOnly
      ] : null,
      focusNode: widget.node ,
      controller: widget.controller,
      maxLines: widget.isMaxLines ? null : widget.maxLines ?? 1,
      style: Theme.of(context).textTheme.bodyMedium,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength != null ? widget.maxLength! + 1 : null,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        helperText: widget.helper,
        helperStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.secondary, fontSize: 13.sp),
        suffixText: widget.suffixText,
        suffixStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).hintColor),
        suffix: widget.suffixText == null ? GestureDetector(
            onTap: ()=> widget.controller.clear(),
            child: Icon(BootstrapIcons.x_circle_fill, size: 18.r,)) : null,
        labelText: widget.label,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
        counterText: '',
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).highlightColor
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        errorText: _valid ? null : errorText,
        errorStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.error, fontSize: 13.sp),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        contentPadding: EdgeInsets.only(left: 16.w, right: 12.w, bottom: 20.h),
      ),
    );
  }
}

