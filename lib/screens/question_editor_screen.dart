// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/arabic_numbers.dart';
import '../services/questions_provider.dart';
import '../models/question_model.dart';

class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({super.key});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _explanationController = TextEditingController();
  final List<TextEditingController> _choiceControllers = [];
  int? _correctIndex;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 4; i++) {
      _choiceControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _choiceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addChoice() =>
      setState(() => _choiceControllers.add(TextEditingController()));

  void _removeChoice(int index) {
    if (index < 0 || index >= _choiceControllers.length) return;
    _choiceControllers[index].dispose();
    setState(() {
      _choiceControllers.removeAt(index);
      if (_correctIndex != null) {
        if (_correctIndex == index) {
          _correctIndex = null;
        } else if (_correctIndex! > index)
          _correctIndex = _correctIndex! - 1;
      }
    });
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    final qText = _questionController.text.trim();
    final explanation = _explanationController.text.trim();
    final choices = _choiceControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (choices.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة خيارين على الأقل')),
      );
      return;
    }
    if (_correctIndex == null ||
        _correctIndex! < 0 ||
        _correctIndex! >= choices.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدد الخيار الصحيح')));
      return;
    }

    final chosen = choices[_correctIndex!];
    double.tryParse(chosen.replaceAll(',', '.'));

    final question = Question.multipleChoice(
      qText,
      choices,
      _correctIndex!,
      explanation: explanation.isEmpty ? null : explanation,
    );

    await Provider.of<QuestionsProvider>(
      context,
      listen: false,
    ).addQuestion(question);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ السؤال')));
    Navigator.of(context).pop();
  }

  List<String> _generateChoices(String correct) {
    final Set<String> s = {correct};
    final num? n = num.tryParse(correct.replaceAll(',', '.'));
    if (n != null) {
      int base = n.round();
      int delta = 1;
      while (s.length < 4) {
        s.add((base + delta).toString());
        if (s.length >= 4) break;
        s.add((base - delta).toString());
        delta++;
      }
    } else {
      int i = 1;
      while (s.length < 4) {
        s.add('$correct ($i)');
        i++;
      }
    }
    final list = s.toList();
    list.shuffle();
    return list;
  }

  Future<void> _quickFillDialog() async {
    final aCtrl = TextEditingController();
    final bCtrl = TextEditingController();
    OperationType op = OperationType.addition;
    int blankPos = 1;

    final map = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (c, s) {
            return AlertDialog(
              title: const Text('أنشئ مسألة حسابية سريعة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<OperationType>(
                    initialValue: op,
                    items: const [
                      DropdownMenuItem(
                        value: OperationType.addition,
                        child: Text('+ جمع'),
                      ),
                      DropdownMenuItem(
                        value: OperationType.subtraction,
                        child: Text('- طرح'),
                      ),
                      DropdownMenuItem(
                        value: OperationType.multiplication,
                        child: Text('× ضرب'),
                      ),
                      DropdownMenuItem(
                        value: OperationType.division,
                        child: Text('÷ قسمة'),
                      ),
                    ],
                    onChanged: (v) => s(() => op = v ?? OperationType.addition),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: aCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الحد الأول',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: bCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الحد الثاني',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('اختر الجزء الذي سيُخفي (المكان الفارغ)'),
                  ),
                  RadioListTile<int>(
                    value: 0,
                    groupValue: blankPos,
                    title: const Text('الحد الأول (a)'),
                    onChanged: (v) => s(() => blankPos = v ?? 0),
                  ),
                  RadioListTile<int>(
                    value: 1,
                    groupValue: blankPos,
                    title: const Text('الحد الثاني (b)'),
                    onChanged: (v) => s(() => blankPos = v ?? 1),
                  ),
                  RadioListTile<int>(
                    value: 2,
                    groupValue: blankPos,
                    title: const Text('الناتج'),
                    onChanged: (v) => s(() => blankPos = v ?? 2),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop({
                    'a': aCtrl.text,
                    'b': bCtrl.text,
                    'op': op,
                    'blank': blankPos,
                  }),
                  child: const Text('أضف'),
                ),
              ],
            );
          },
        );
      },
    );

    if (map == null) return;

    final int a = int.tryParse((map['a'] as String?) ?? '') ?? 0;
    final int b = int.tryParse((map['b'] as String?) ?? '') ?? 0;
    final OperationType opSel = map['op'] as OperationType;
    final int blank = map['blank'] as int;

    double resultVal;
    switch (opSel) {
      case OperationType.addition:
        resultVal = (a + b).toDouble();
        break;
      case OperationType.subtraction:
        resultVal = (a - b).toDouble();
        break;
      case OperationType.multiplication:
        resultVal = (a * b).toDouble();
        break;
      case OperationType.division:
        resultVal = b == 0 ? 0 : a / b;
        break;
    }

    String symbol;
    switch (opSel) {
      case OperationType.addition:
        symbol = '+';
        break;
      case OperationType.subtraction:
        symbol = '-';
        break;
      case OperationType.multiplication:
        symbol = '×';
        break;
      case OperationType.division:
        symbol = '÷';
        break;
    }

    String fa(int val) => toArabicDigits(val.toString());
    String fr(double v) => v == v.roundToDouble()
        ? toArabicDigits(v.toInt().toString())
        : toArabicDigits(v.toString());

    String questionText;
    String correctStr;

    if (blank == 0) {
      questionText = '... $symbol ${fa(b)} = ${fr(resultVal)}';
      correctStr = a.toString();
    } else if (blank == 1) {
      questionText = '${fa(a)} $symbol ... = ${fr(resultVal)}';
      correctStr = b.toString();
    } else {
      questionText = '${fa(a)} $symbol ${fa(b)} = ...';
      correctStr = fr(resultVal);
    }

    final generated = _generateChoices(correctStr);
    final correctIndex = generated.indexOf(correctStr);

    setState(() {
      _questionController.text = questionText;
      while (_choiceControllers.length < generated.length) {
        _choiceControllers.add(TextEditingController());
      }
      for (int i = 0; i < generated.length; i++) {
        _choiceControllers[i].text = generated[i];
      }
      _correctIndex = correctIndex >= 0 ? correctIndex : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر السؤال'),
        actions: [
          TextButton(
            onPressed: _saveQuestion,
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'نص السؤال',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'الرجاء إدخال نص السؤال'
                    : null,
              ),
              const SizedBox(height: 12),
              const Text('الاختيارات (يمكن إضافة/حذف)'),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _choiceControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctIndex,
                          onChanged: (v) => setState(() => _correctIndex = v),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _choiceControllers[index],
                            decoration: InputDecoration(
                              labelText: 'خيار ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'الرجاء إدخال نص للاختيار'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _choiceControllers.length <= 2
                              ? null
                              : () => _removeChoice(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addChoice,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة اختيار'),
                  ),
                  const SizedBox(width: 2),
                  ElevatedButton.icon(
                    onPressed: _quickFillDialog,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text(
                      'ملئ أوتوماتيكي للمسألة',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _explanationController,
                decoration: const InputDecoration(
                  labelText: 'الشرح (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveQuestion,
                icon: const Icon(Icons.save),
                label: const Text('حفظ السؤال'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
