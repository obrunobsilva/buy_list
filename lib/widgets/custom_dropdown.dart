import 'package:flutter/material.dart';

class CustomDropdownButtonFormField extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const CustomDropdownButtonFormField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: "Qtd",
        labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
      ),
      items: List.generate(99, (index) => index + 1)
          .map(
            (qtd) => DropdownMenuItem(value: qtd, child: Text(qtd.toString())),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
