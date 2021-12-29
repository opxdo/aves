import 'package:aves/model/entry.dart';
import 'package:aves/model/metadata/date_modifier.dart';
import 'package:aves/model/metadata/enums.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/wheel.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/providers/media_query_data_provider.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditEntryDateDialog extends StatefulWidget {
  final AvesEntry entry;

  const EditEntryDateDialog({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  _EditEntryDateDialogState createState() => _EditEntryDateDialogState();
}

class _EditEntryDateDialogState extends State<EditEntryDateDialog> {
  DateEditAction _action = DateEditAction.set;
  DateSetSource _setSource = DateSetSource.custom;
  late DateTime _setDateTime;
  late ValueNotifier<int> _shiftHour, _shiftMinute;
  late ValueNotifier<String> _shiftSign;
  bool _showOptions = false;
  final Set<MetadataField> _fields = {
    MetadataField.exifDate,
    MetadataField.exifDateDigitized,
    MetadataField.exifDateOriginal,
  };

  // use a different shade to avoid having the same background
  // on the dialog (using the theme `dialogBackgroundColor`)
  // and on the dropdown (using the theme `canvasColor`)
  static final dropdownColor = Colors.grey.shade800;

  @override
  void initState() {
    super.initState();
    _initSet();
    _initShift(60);
  }

  void _initSet() {
    _setDateTime = widget.entry.bestDate ?? DateTime.now();
  }

  void _initShift(int initialMinutes) {
    final abs = initialMinutes.abs();
    _shiftHour = ValueNotifier(abs ~/ 60);
    _shiftMinute = ValueNotifier(abs % 60);
    _shiftSign = ValueNotifier(initialMinutes.isNegative ? '-' : '+');
  }

  @override
  Widget build(BuildContext context) {
    return MediaQueryDataProvider(
      child: TooltipTheme(
        data: TooltipTheme.of(context).copyWith(
          preferBelow: false,
        ),
        child: Builder(builder: (context) {
          final l10n = context.l10n;

          return AvesDialog(
            title: l10n.editEntryDateDialogTitle,
            scrollableContent: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
                child: DropdownButton<DateEditAction>(
                  items: DateEditAction.values
                      .map((v) => DropdownMenuItem<DateEditAction>(
                            value: v,
                            child: Text(_actionText(context, v)),
                          ))
                      .toList(),
                  value: _action,
                  onChanged: (v) => setState(() => _action = v!),
                  isExpanded: true,
                  dropdownColor: dropdownColor,
                ),
              ),
              AnimatedSwitcher(
                duration: context.read<DurationsData>().formTransition,
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: _formTransitionBuilder,
                child: Column(
                  key: ValueKey(_action),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_action == DateEditAction.set) ..._buildSetContent(context),
                    if (_action == DateEditAction.shift) _buildShiftContent(context),
                  ],
                ),
              ),
              _buildDestinationFields(context),
            ],
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => _submit(context),
                child: Text(l10n.applyButtonLabel),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _formTransitionBuilder(Widget child, Animation<double> animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: child,
        ),
      );

  List<Widget> _buildSetContent(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final use24hour = context.select<MediaQueryData, bool>((v) => v.alwaysUse24HourFormat);

    return [
      Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Row(
          children: [
            Text(l10n.editEntryDateDialogSourceFieldLabel),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<DateSetSource>(
                items: DateSetSource.values
                    .map((v) => DropdownMenuItem<DateSetSource>(
                          value: v,
                          child: Text(_setSourceText(context, v)),
                        ))
                    .toList(),
                selectedItemBuilder: (context) => DateSetSource.values
                    .map((v) => DropdownMenuItem<DateSetSource>(
                          value: v,
                          child: Text(
                            _setSourceText(context, v),
                            softWrap: false,
                            overflow: TextOverflow.fade,
                          ),
                        ))
                    .toList(),
                value: _setSource,
                onChanged: (v) => setState(() => _setSource = v!),
                isExpanded: true,
                dropdownColor: dropdownColor,
              ),
            ),
          ],
        ),
      ),
      AnimatedSwitcher(
        duration: context.read<DurationsData>().formTransition,
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: _formTransitionBuilder,
        child: _setSource == DateSetSource.custom
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(formatDateTime(_setDateTime, locale, use24hour))),
                    IconButton(
                      icon: const Icon(AIcons.edit),
                      onPressed: _editDate,
                      tooltip: l10n.changeTooltip,
                    ),
                  ],
                ),
              )
            : const SizedBox(),
      ),
    ];
  }

  Widget _buildShiftContent(BuildContext context) {
    const textStyle = TextStyle(fontSize: 34);
    return Center(
      child: Table(
        children: [
          TableRow(
            children: [
              const SizedBox(),
              Center(child: Text(context.l10n.editEntryDateDialogHours)),
              const SizedBox(),
              Center(child: Text(context.l10n.editEntryDateDialogMinutes)),
            ],
          ),
          TableRow(
            children: [
              WheelSelector(
                valueNotifier: _shiftSign,
                values: const ['+', '-'],
                textStyle: textStyle,
                textAlign: TextAlign.center,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: WheelSelector(
                  valueNotifier: _shiftHour,
                  values: List.generate(24, (i) => i),
                  textStyle: textStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  ':',
                  style: textStyle,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: WheelSelector(
                  valueNotifier: _shiftMinute,
                  values: List.generate(60, (i) => i),
                  textStyle: textStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          )
        ],
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      ),
    );
  }

  Widget _buildDestinationFields(BuildContext context) {
    return Padding(
      // small padding as a workaround to show dialog action divider
      padding: const EdgeInsets.only(bottom: 1),
      child: ExpansionPanelList(
        expansionCallback: (index, isExpanded) {
          setState(() => _showOptions = !isExpanded);
        },
        animationDuration: context.read<DurationsData>().expansionTileAnimation,
        expandedHeaderPadding: EdgeInsets.zero,
        elevation: 0,
        children: [
          ExpansionPanel(
            headerBuilder: (context, isExpanded) => ListTile(
              title: Text(context.l10n.editEntryDateDialogTargetFieldsHeader),
            ),
            body: Column(
              children: DateModifier.writableDateFields
                  .map((field) => SwitchListTile(
                        value: _fields.contains(field),
                        onChanged: (selected) => setState(() => selected ? _fields.add(field) : _fields.remove(field)),
                        title: Text(_fieldTitle(field)),
                      ))
                  .toList(),
            ),
            isExpanded: _showOptions,
            canTapOnHeader: true,
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  String _actionText(BuildContext context, DateEditAction action) {
    final l10n = context.l10n;
    switch (action) {
      case DateEditAction.set:
        return l10n.editEntryDateDialogSet;
      case DateEditAction.shift:
        return l10n.editEntryDateDialogShift;
      case DateEditAction.clear:
        return l10n.editEntryDateDialogClear;
    }
  }

  String _setSourceText(BuildContext context, DateSetSource source) {
    final l10n = context.l10n;
    switch (source) {
      case DateSetSource.custom:
        return l10n.editEntryDateDialogSourceCustomDate;
      case DateSetSource.title:
        return l10n.editEntryDateDialogSourceTitle;
      case DateSetSource.fileModifiedDate:
        return l10n.editEntryDateDialogSourceFileModifiedDate;
      case DateSetSource.exifDate:
        return 'Exif date';
      case DateSetSource.exifDateOriginal:
        return 'Exif original date';
      case DateSetSource.exifDateDigitized:
        return 'Exif digitized date';
      case DateSetSource.exifGpsDate:
        return 'Exif GPS date';
    }
  }

  String _fieldTitle(MetadataField field) {
    switch (field) {
      case MetadataField.exifDate:
        return 'Exif date';
      case MetadataField.exifDateOriginal:
        return 'Exif original date';
      case MetadataField.exifDateDigitized:
        return 'Exif digitized date';
      case MetadataField.exifGpsDate:
        return 'Exif GPS date';
    }
  }

  Future<void> _editDate() async {
    final _date = await showDatePicker(
      context: context,
      initialDate: _setDateTime,
      firstDate: DateTime(0),
      lastDate: DateTime.now(),
      confirmText: context.l10n.nextButtonLabel,
    );
    if (_date == null) return;

    final _time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_setDateTime),
    );
    if (_time == null) return;

    setState(() => _setDateTime = DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ));
  }

  void _submit(BuildContext context) {
    late DateModifier modifier;
    switch (_action) {
      case DateEditAction.set:
        modifier = DateModifier(_action, _fields, setSource: _setSource, setDateTime: _setDateTime);
        break;
      case DateEditAction.shift:
        final shiftTotalMinutes = (_shiftHour.value * 60 + _shiftMinute.value) * (_shiftSign.value == '+' ? 1 : -1);
        modifier = DateModifier(_action, _fields, shiftMinutes: shiftTotalMinutes);
        break;
      case DateEditAction.clear:
        modifier = DateModifier(_action, _fields);
        break;
    }
    Navigator.pop(context, modifier);
  }
}