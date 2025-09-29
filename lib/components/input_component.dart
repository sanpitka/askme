import 'package:flutter/material.dart';

class InputComponent extends StatelessWidget {
  final String group;
  final TextEditingController? controller;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  
  const InputComponent({
    super.key, 
    required this.group, 
    this.controller,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: textInputAction ?? TextInputAction.done,
            onFieldSubmitted: (_) => onSubmitted?.call(),
            decoration: InputDecoration(
              labelText: group,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}