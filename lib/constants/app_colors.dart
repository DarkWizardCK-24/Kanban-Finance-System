import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Dark Vault Palette ────────────────────────────────────────
  static const Color darkBg      = Color(0xFF090E1A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard    = Color(0xFF141E30);
  static const Color darkCardAlt = Color(0xFF1A2438);
  static const Color darkBorder  = Color(0xFF253450);
  static const Color darkDivider = Color(0xFF1E2B42);

  // Text on dark backgrounds
  static const Color textPrimary   = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8B9DC3);
  static const Color textHint      = Color(0xFF4A5B7A);
  static const Color textMuted     = Color(0xFF2E3D5A);

  // Accent colors
  static const Color accentCyan   = Color(0xFF4FC3F7);
  static const Color accentGold   = Color(0xFFFFD54F);
  static const Color accentGreen  = Color(0xFF4ADE80);
  static const Color accentAmber  = Color(0xFFFBBF24);
  static const Color accentRed    = Color(0xFFF87171);
  static const Color accentPurple = Color(0xFFA78BFA);

  // ── Compatibility Aliases ─────────────────────────────────────
  static const Color greenAccent      = accentCyan;
  static const Color greenAccentLight = Color(0xFF38BDF8);
  static const Color greenAccentDark  = Color(0xFF0EA5E9);
  static const Color greenAccentDeep  = Color(0xFF06B6D4);
  static const Color primaryCyan      = accentCyan;
  static const Color primaryBlue      = Color(0xFF3B82F6);
  static const Color primaryAmber     = accentAmber;
  static const Color primaryYellow    = Color(0xFFFDE68A);

  static const Color lightGreen  = Color(0xFF0A1F12);
  static const Color lightCyan   = Color(0xFF091E2A);
  static const Color lightBlue   = Color(0xFF0A152A);
  static const Color lightAmber  = Color(0xFF1F1508);
  static const Color lightYellow = Color(0xFF1F1C08);

  static const Color cyanAccent = accentCyan;
  static const Color blueAccent = Color(0xFF60A5FA);

  static const Color background = darkBg;
  static const Color surface    = darkSurface;
  static const Color cardBg     = darkCard;
  static const Color divider    = darkDivider;
  static const Color border     = darkBorder;

  static const Color success = accentGreen;
  static const Color warning = accentAmber;
  static const Color error   = accentRed;
  static const Color info    = accentCyan;

  // Kanban column backgrounds (dark variants)
  static const Color kanbanPending    = Color(0xFF1A1200);
  static const Color kanbanProcessing = Color(0xFF001525);
  static const Color kanbanCompleted  = Color(0xFF001A0E);
  static const Color kanbanFailed     = Color(0xFF1A0606);

  // ── Bank Brand Gradients ──────────────────────────────────────
  // SBI / State Bank of India — light sky blue
  static const List<Color> gradientSBI      = [Color(0xFF1565C0), Color(0xFF42A5F5)];
  // Bank of India — deep navy blue
  static const List<Color> gradientBOI      = [Color(0xFF0D47A1), Color(0xFF1A237E)];
  // HDFC Bank — dark blue + dark red mix
  static const List<Color> gradientHDFC     = [Color(0xFF0D1B5E), Color(0xFF991B1B)];
  // Kotak Mahindra — dark crimson red
  static const List<Color> gradientKotak    = [Color(0xFF7F1D1D), Color(0xFF450A0A)];
  // IDFC First Bank — light-medium red
  static const List<Color> gradientIDFC     = [Color(0xFFDC2626), Color(0xFF991B1B)];
  // Axis Bank — royal purple to maroon
  static const List<Color> gradientAxis     = [Color(0xFF4C1D95), Color(0xFF831843)];
  // ICICI Bank — deep red to purple
  static const List<Color> gradientICICI    = [Color(0xFF991B1B), Color(0xFF4C1D95)];
  // PNB / Punjab National Bank — forest green
  static const List<Color> gradientPNB      = [Color(0xFF14532D), Color(0xFF134E4A)];
  // Canara Bank — indigo
  static const List<Color> gradientCanara   = [Color(0xFF3730A3), Color(0xFF1E1B4B)];
  // Union Bank of India — dark teal
  static const List<Color> gradientUnion    = [Color(0xFF134E4A), Color(0xFF065F46)];
  // Yes Bank — cobalt blue
  static const List<Color> gradientYesBank  = [Color(0xFF1D4ED8), Color(0xFF1E3A8A)];
  // IndusInd Bank — violet purple
  static const List<Color> gradientIndusInd = [Color(0xFF5B21B6), Color(0xFF3730A3)];
  // India Post / IPPB / Postal Savings — forest green + olive
  static const List<Color> gradientPostal   = [Color(0xFF166534), Color(0xFF365314)];
  // RBL Bank — burnt amber
  static const List<Color> gradientRBL      = [Color(0xFFB45309), Color(0xFF7C2D12)];
  // Federal Bank — medium blue
  static const List<Color> gradientFederal  = [Color(0xFF1E40AF), Color(0xFF1D4ED8)];
  // Bandhan Bank — ocean teal
  static const List<Color> gradientBandhan  = [Color(0xFF065F46), Color(0xFF164E63)];
  // Bank of Baroda — charcoal navy
  static const List<Color> gradientBOB      = [Color(0xFF1C1917), Color(0xFF1E3A8A)];
  // Citibank — deep blue cyan
  static const List<Color> gradientCiti     = [Color(0xFF1E3A8A), Color(0xFF164E63)];
  // Standard Chartered — dark charcoal
  static const List<Color> gradientStandard = [Color(0xFF1C1917), Color(0xFF292524)];
  // DBS Bank — dark red
  static const List<Color> gradientDBS      = [Color(0xFF7F1D1D), Color(0xFF991B1B)];
  // BOB / Bank of Baroda — brown to blue
  static const List<Color> gradientBOBalt   = [Color(0xFF4E342E), Color(0xFF1E3A8A)];

  // ── Category Fallback Gradients ───────────────────────────────
  static const List<Color> gradientSavings   = [Color(0xFF14532D), Color(0xFF166534)];
  static const List<Color> gradientExpenses  = [Color(0xFF7C2D12), Color(0xFFB45309)];
  static const List<Color> gradientFixed     = [Color(0xFF134E4A), Color(0xFF065F46)];
  static const List<Color> gradientCurrent   = [Color(0xFF1E3A8A), Color(0xFF1D4ED8)];
  static const List<Color> gradientSalary    = [Color(0xFF1E1B4B), Color(0xFF3730A3)];
  static const List<Color> gradientRecurring = [Color(0xFF164E63), Color(0xFF0C4A6E)];
  static const List<Color> gradientNRI       = [Color(0xFF4C1D95), Color(0xFF5B21B6)];
  static const List<Color> gradientBusiness  = [Color(0xFF1C1917), Color(0xFF292524)];

  // ── App-wide Gradients ────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0D1B5E), Color(0xFF134E4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient wealthGradient = LinearGradient(
    colors: [Color(0xFF0D1B5E), Color(0xFF090E1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Bank Name → Gradient Lookup ───────────────────────────────
  /// Returns bank-specific gradient colors based on [bankName], or empty list
  /// to signal that a category-based fallback should be used.
  static List<Color> bankGradient(String bankName) {
    final n = bankName.toLowerCase();
    if (n.contains('sbi') || n.contains('state bank')) return gradientSBI;
    if (n.contains('boi') || (n.contains('bank of india') && !n.contains('baroda'))) return gradientBOI;
    if (n.contains('hdfc')) return gradientHDFC;
    if (n.contains('kotak')) return gradientKotak;
    if (n.contains('idfc')) return gradientIDFC;
    if (n.contains('axis')) return gradientAxis;
    if (n.contains('icici')) return gradientICICI;
    if (n.contains('pnb') || n.contains('punjab national')) return gradientPNB;
    if (n.contains('canara')) return gradientCanara;
    if (n.contains('union bank')) return gradientUnion;
    if (n.contains('yes bank') || n.contains('yesbank')) return gradientYesBank;
    if (n.contains('indusind') || n.contains('indus ind')) return gradientIndusInd;
    // Post Office / Postal Savings — any bank name containing 'post', 'postal', 'ippb', etc.
    if (n.contains('post office') || n.contains('postal') || n.contains('ippb') ||
        n.contains('india post') || n.contains('posb') ||
        (n.startsWith('post') && n.length < 20) ||
        (n.contains('post') && (n.contains('saving') || n.contains('bank') || n.contains('office')))) {
      return gradientPostal;
    }
    if (n.contains('rbl')) return gradientRBL;
    if (n.contains('federal')) return gradientFederal;
    if (n.contains('bandhan')) return gradientBandhan;
    if (n.contains('baroda') || n.contains('bob')) return gradientBOBalt;
    if (n.contains('citi')) return gradientCiti;
    if (n.contains('standard') || n.contains('stanchart') || n.contains('chartered')) return gradientStandard;
    if (n.contains('dbs')) return gradientDBS;
    return []; // empty → caller uses category fallback
  }
}