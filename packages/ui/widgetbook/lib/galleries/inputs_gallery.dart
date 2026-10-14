import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

/// TextField, SearchField, QtyStepper.
class InputsGallery extends StatefulWidget {
  const InputsGallery({super.key});

  @override
  State<InputsGallery> createState() => _InputsGalleryState();
}

class _InputsGalleryState extends State<InputsGallery> {
  final _filled = TextEditingController(text: 'Non "Buxoro"');
  final _search = TextEditingController(text: 'sut');
  final _error = TextEditingController(text: '12a');

  @override
  void dispose() {
    _filled.dispose();
    _search.dispose();
    _error.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fieldWidth = 320.0;
    return GalleryPage(
      sections: [
        GallerySection(
          title: 'TextField',
          children: [
            const SizedBox(
              width: fieldWidth,
              child: PosTextField(
                label: 'Tovar nomi',
                hint: 'Masalan: Non',
                helper: 'Chekda shu nom chiqadi',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: PosTextField(label: "To'ldirilgan", controller: _filled),
            ),
            SizedBox(
              width: fieldWidth,
              child: PosTextField(
                label: 'Narx',
                controller: _error,
                errorText: 'Faqat raqam kiriting',
              ),
            ),
            const SizedBox(
              width: fieldWidth,
              child: PosTextField(
                label: "O'chiq",
                hint: 'Tahrirlab bo‘lmaydi',
                enabled: false,
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'SearchField',
          children: [
            const SizedBox(
              width: fieldWidth,
              child: PosSearchField(
                hint: 'Tovar qidirish',
                clearTooltip: 'Tozalash',
                shortcut: 'F1',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: PosSearchField(
                hint: 'Tovar qidirish',
                clearTooltip: 'Tozalash',
                controller: _search,
                large: true,
              ),
            ),
          ],
        ),
        const GallerySection(
          title: 'QtyStepper',
          children: [
            PosQtyStepper(
              valueMilli: 3000,
              onChanged: noopValue,
              decrementTooltip: 'Kamaytirish',
              incrementTooltip: "Ko'paytirish",
            ),
            PosQtyStepper(
              valueMilli: 1000,
              minMilli: 1000,
              onChanged: noopValue,
              decrementTooltip: 'Kamaytirish',
              incrementTooltip: "Ko'paytirish",
            ),
            PosQtyStepper(
              valueMilli: 1250,
              stepMilli: 250,
              weighted: true,
              unit: 'kg',
              large: true,
              onChanged: noopValue,
              decrementTooltip: 'Kamaytirish',
              incrementTooltip: "Ko'paytirish",
            ),
          ],
        ),
      ],
    );
  }
}
