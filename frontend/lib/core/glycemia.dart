import 'package:flutter/material.dart';

import 'theme.dart';

/// Statuts de glycémie (mêmes seuils que le backend, en g/L).
enum GStatus { hypoSevere, hypo, normal, legerementEleve, eleve, critique }

GStatus statusFromValue(double v, double cmin, double cmax) {
  if (v < 0.54) return GStatus.hypoSevere;
  if (v < cmin) return GStatus.hypo;
  if (v <= cmax) return GStatus.normal;
  if (v <= 1.80) return GStatus.legerementEleve;
  if (v <= 2.50) return GStatus.eleve;
  return GStatus.critique;
}

GStatus statusFromServer(String? s) {
  switch (s) {
    case 'HYPO_SEVERE':
      return GStatus.hypoSevere;
    case 'HYPO':
      return GStatus.hypo;
    case 'LEGEREMENT_ELEVE':
      return GStatus.legerementEleve;
    case 'ELEVE':
      return GStatus.eleve;
    case 'CRITIQUE':
      return GStatus.critique;
    default:
      return GStatus.normal;
  }
}

String statusToServer(GStatus s) {
  switch (s) {
    case GStatus.hypoSevere:
      return 'HYPO_SEVERE';
    case GStatus.hypo:
      return 'HYPO';
    case GStatus.normal:
      return 'NORMAL';
    case GStatus.legerementEleve:
      return 'LEGEREMENT_ELEVE';
    case GStatus.eleve:
      return 'ELEVE';
    case GStatus.critique:
      return 'CRITIQUE';
  }
}

/// Clés de traduction : status_<nom> et interp_<nom>.
String statusKey(GStatus s) => 'status_${statusToServer(s).toLowerCase()}';
String interpKey(GStatus s) => 'interp_${statusToServer(s).toLowerCase()}';

Color statusColor(GStatus s) {
  switch (s) {
    case GStatus.normal:
      return AppColors.green;
    case GStatus.hypo:
    case GStatus.legerementEleve:
      return AppColors.orange;
    case GStatus.eleve:
      return AppColors.deepOrange;
    case GStatus.hypoSevere:
    case GStatus.critique:
      return AppColors.red;
  }
}

Color statusSoft(GStatus s) {
  switch (s) {
    case GStatus.normal:
      return AppColors.greenSoft;
    case GStatus.hypo:
    case GStatus.legerementEleve:
    case GStatus.eleve:
      return AppColors.orangeSoft;
    case GStatus.hypoSevere:
    case GStatus.critique:
      return AppColors.redSoft;
  }
}

bool isUrgent(GStatus s) => s == GStatus.hypoSevere || s == GStatus.critique;

const List<String> kMoments = [
  'A_JEUN',
  'AVANT_REPAS',
  'APRES_REPAS',
  'COUCHER',
];
String momentKey(String m) => 'moment_${m.toLowerCase()}';
