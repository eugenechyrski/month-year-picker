import 'package:flutter/material.dart';


DateTime monthYearOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month);
}

bool debugCheckHasMonthYearPickerLocalizations(BuildContext context) {

  return true;
}
