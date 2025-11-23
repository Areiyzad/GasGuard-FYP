import 'package:flutter/material.dart';
import 'widgets/glassy.dart';

class LearnPreventPage extends StatefulWidget {
  const LearnPreventPage({super.key});

  @override
  State<LearnPreventPage> createState() => _LearnPreventPageState();
}

class _LearnPreventPageState extends State<LearnPreventPage>
    with TickerProviderStateMixin {
  String? _selectedGuide;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _fadeController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn & Prevent',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  Text(
                    'Gas safety education and emergency protocols',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
            // New: Hero banner
            _buildHeroBanner(),
            const SizedBox(height: 16.0),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _selectedGuide == null
                  ? _buildGuideMenu()
                  : _buildGuideContent(_selectedGuide!),
            ),
          ],
        ),
      ),
    );
  }

  // New: Attractive hero banner with quick facts chips
  Widget _buildHeroBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: Opacity(opacity: value, child: child));
      },
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.health_and_safety, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stay Safe, Stay Aware',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Learn how gas behaves, how to ventilate, and what to do in emergencies.',
                    style: TextStyle(color: Colors.white.withOpacity(0.95), height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _InfoPill(text: 'LPG sinks ↓'),
                      _InfoPill(text: 'NG rises ↑'),
                      _InfoPill(text: 'CO is odorless'),
                      _InfoPill(text: 'Test monthly'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideMenu() {
    return Column(
      key: const ValueKey('menu'),
      children: [
        _buildAnimatedMenuCard(
          delay: 0,
          title: 'Gas Safety Guide',
          subtitle: 'Learn best practices and prevention',
          icon: Icons.book,
          gradient: LinearGradient(
            colors: [const Color(0xFF3B82F6), const Color(0xFF1E40AF)],
            end: Alignment.bottomRight,
          ),
          onTap: () => setState(() => _selectedGuide = 'safety'),
        ),
        const SizedBox(height: 16.0),
        _buildAnimatedMenuCard(
          delay: 100,
          title: 'Emergency Steps',
          subtitle: 'What to do when alarm sounds',
          icon: Icons.warning_amber_rounded,
          gradient: LinearGradient(
            colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            end: Alignment.bottomRight,
          ),
          onTap: () => setState(() => _selectedGuide = 'emergency'),
        ),
        const SizedBox(height: 16.0),
        // New topics
        _buildAnimatedMenuCard(
          delay: 200,
          title: 'Gas Types & Behavior',
          subtitle: 'NG, LPG and CO differences',
          icon: Icons.category,
          gradient: LinearGradient(
            colors: [const Color(0xFF10B981), const Color(0xFF0EA5E9)],
            end: Alignment.bottomRight,
          ),
          onTap: () => setState(() => _selectedGuide = 'types'),
        ),
        const SizedBox(height: 16.0),
        _buildAnimatedMenuCard(
          delay: 300,
          title: 'Ventilation Basics',
          subtitle: 'Airflow and placement tips',
          icon: Icons.air,
          gradient: LinearGradient(
            colors: [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
            end: Alignment.bottomRight,
          ),
          onTap: () => setState(() => _selectedGuide = 'ventilation'),
        ),
        const SizedBox(height: 16.0),
        _buildAnimatedMenuCard(
          delay: 400,
          title: 'Storage & Handling',
          subtitle: 'Cylinders and safe practices',
          icon: Icons.inventory_2,
          gradient: LinearGradient(
            colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
            end: Alignment.bottomRight,
          ),
          onTap: () => setState(() => _selectedGuide = 'storage'),
        ),
        const SizedBox(height: 16.0),
        _buildAnimatedMenuCard(
          delay: 500,
          title: 'Myths vs Facts',
          subtitle: 'Clear common misconceptions',
          icon: Icons.fact_check,
          gradient: LinearGradient(
            colors: [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)],
            end: Alignment.bottomRight,
          ),
          onTap: () => setState(() => _selectedGuide = 'myths'),
        ),
      ],
    );
  }

  Widget _buildAnimatedMenuCard({
    required int delay,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(12.0),
        padding: const EdgeInsets.all(24.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 32.0, color: Colors.white),
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideContent(String guideType) {
    return Column(
      key: ValueKey(guideType),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
          ),
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back, size: 16.0),
            label: const Text('Back to Guides'),
            onPressed: () => setState(() => _selectedGuide = null),
          ),
        ),
        const SizedBox(height: 16.0),
        // Updated routing for more content types
        if (guideType == 'safety') _buildSafetyGuideContent()
        else if (guideType == 'emergency') _buildEmergencyStepsContent()
        else if (guideType == 'types') _buildGasTypesContent()
        else if (guideType == 'ventilation') _buildVentilationContent()
        else if (guideType == 'storage') _buildStorageHandlingContent()
        else if (guideType == 'myths') _buildMythFactContent()
        else _buildSafetyGuideContent(),
      ],
    );
  }

  Widget _buildSafetyGuideContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gas Safety Guide',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
          color: Colors.white,
              ),
        ),
        const SizedBox(height: 16.0),
        _buildAnimatedSafetyCard(
          delay: 0,
          title: 'Installation & Placement',
          icon: Icons.home,
          color: const Color(0xFF3B82F6),
          tips: [
            'Minimum one detector per floor recommended',
            'Place detectors near potential gas sources',
            'Keep 4-12 inches away from cooking appliances',
            'Install at eye level or on ceilings for better detection',
            'Avoid placing near windows or air vents',
          ],
        ),
        _buildAnimatedSafetyCard(
          delay: 100,
          title: 'Maintenance & Testing',
          icon: Icons.shield,
          color: const Color(0xFF10B981),
          tips: [
            'Test monthly by pressing the test button for 3 seconds',
            'Replace entire unit every 5-7 years',
            'Clean sensor vents quarterly with a soft brush',
            'Battery replacement: annually or when low indicator shows',
            'Keep detector dust-free for optimal performance',
          ],
        ),
        _buildAnimatedSafetyCard(
          delay: 200,
          title: 'Prevention Methods',
          icon: Icons.air,
          color: const Color(0xFF8B5CF6),
          tips: [
            'Schedule annual professional gas line inspection',
            'Install carbon monoxide detector with gas detector',
            'Never use stove/oven to heat your home',
            'Ensure proper ventilation in gas appliance areas',
            'Keep detector away from humidity and moisture',
          ],
        ),
        _buildAnimatedSafetyCard(
          delay: 300,
          title: 'Signs of Gas Leak',
          icon: Icons.warning_rounded,
          color: const Color(0xFFF59E0B),
          tips: [
            'Rotten egg smell near gas appliances',
            'Hissing sound from gas lines or appliances',
            'Dead plants or vegetation near gas lines',
            'Soot or discoloration around appliances',
            'Dizziness, nausea, or headaches indoors',
          ],
        ),
        const SizedBox(height: 24.0),
        Text(
          'Common Questions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 16.0),
        _buildFAQCard(
          question: 'How often should I test my detector?',
          answer:
              'At least once per month. Press and hold the test button until the alarm sounds (usually 3-5 seconds). This ensures the alarm mechanism is working properly.',
        ),
        _buildFAQCard(
          question: 'What should I do if I smell gas?',
          answer:
              'Leave immediately, go to fresh air, and call your gas company from a safe location. Do not turn on/off electrical switches or use phones inside.',
        ),
        _buildFAQCard(
          question: 'Can I move my detector?',
          answer:
              'No, keep it in the same location for consistent protection. Moving it frequently may disrupt safety coverage.',
        ),
      ],
    );
  }

  Widget _buildAnimatedSafetyCard({
    required int delay,
    required String title,
    required IconData icon,
    required Color color,
    required List<String> tips,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(12.0),
        padding: const EdgeInsets.all(20.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: color, size: 24.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ...List.generate(
                tips.length,
                (index) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(
                    milliseconds: 400 + delay + (index * 50),
                  ),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, color: color, size: 18.0),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            tips[index],
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildFAQCard({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(12.0),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            title: Text(
              question,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white70,
            textColor: Colors.white,
            collapsedTextColor: Colors.white,
            children: [
              Text(
                answer,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyStepsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Response',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        Text(
          'Follow these steps if your alarm sounds',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 16.0),
        _buildAnimatedEmergencyCard(
          step: 1,
          title: 'Evacuate Immediately',
          description: 'Leave the building right away without stopping.',
          icon: Icons.exit_to_app,
          color: const Color(0xFFEF4444),
          delay: 0,
        ),
        _buildAnimatedEmergencyCard(
          step: 2,
          title: 'Go to Fresh Air',
          description: 'Move to an open area away from the building.',
          icon: Icons.air,
          color: const Color(0xFFF97316),
          delay: 100,
        ),
        _buildAnimatedEmergencyCard(
          step: 3,
          title: 'Call Emergency Services',
          description: 'Contact gas company or emergency responders.',
          icon: Icons.phone,
          color: const Color(0xFF3B82F6),
          delay: 200,
        ),
        _buildAnimatedEmergencyCard(
          step: 4,
          title: 'Do Not Return',
          description: 'Wait for professionals to clear the building.',
          icon: Icons.block,
          color: const Color(0xFF8B5CF6),
          delay: 300,
        ),
        _buildAnimatedEmergencyCard(
          step: 5,
          title: 'Document & Report',
          description: 'File a report with authorities and your landlord.',
          icon: Icons.description,
          color: const Color(0xFF10B981),
          delay: 400,
        ),
        const SizedBox(height: 16.0),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value, child: child),
            );
          },
          child: GlassyContainer(
            borderRadius: BorderRadius.circular(12.0),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildContactRow('Emergency', '999'),
                _buildContactRow('Gas Leak', '1-800-GAS-LEAK'),
                _buildContactRow('Poison Control', '1-800-222-1222'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedEmergencyCard({
    required int step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: color, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.02)],
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    step.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(String service, String number) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            service,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
          Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }

  // New: Gas types & behavior
  Widget _buildGasTypesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gas Types & Behavior',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
          color: Colors.white,
              ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedSafetyCard(
          delay: 0,
          title: 'Natural Gas (NG)',
          icon: Icons.trending_up,
          color: const Color(0xFF0EA5E9),
          tips: [
            'Lighter than air – tends to rise towards ceilings',
            'Added odorant (mercaptan) smells like sulfur/rotten eggs',
            'Place detectors higher (eye-level or ceiling) near appliances',
          ],
        ),
        _buildAnimatedSafetyCard(
          delay: 100,
          title: 'Liquefied Petroleum Gas (LPG)',
          icon: Icons.arrow_downward,
          color: const Color(0xFF10B981),
          tips: [
            'Heavier than air – can pool near floors and in low spots',
            'Can travel along floors to ignition sources',
            'Place detectors lower (near knee height) in LPG areas',
          ],
        ),
        _buildAnimatedSafetyCard(
          delay: 200,
          title: 'Carbon Monoxide (CO)',
          icon: Icons.circle_outlined,
          color: const Color(0xFFEF4444),
          tips: [
            'Colorless, odorless – requires dedicated CO detectors',
            'Symptoms: headache, dizziness, nausea; act immediately',
            'Install CO detectors near bedrooms and each level',
          ],
        ),
      ],
    );
  }

  // New: Ventilation basics
  Widget _buildVentilationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventilation Basics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
          color: Colors.white,
              ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedSafetyCard(
          delay: 0,
          title: 'Improve Airflow',
          icon: Icons.wind_power,
          color: const Color(0xFFF59E0B),
          tips: [
            'Open windows/doors on opposite sides to create cross-breeze',
            'Use exhaust fans; keep vents unobstructed',
            'Avoid sealing utility rooms too tightly',
          ],
        ),
        _buildAnimatedSafetyCard(
          delay: 120,
          title: 'Detector Placement & Air',
          icon: Icons.place,
          color: const Color(0xFF8B5CF6),
          tips: [
            'Keep detectors away from vents, windows, and fans',
            'Avoid kitchens and bathrooms with high steam/humidity',
            'Mount per gas type behavior (see Gas Types section)',
          ],
        ),
      ],
    );
  }

  // New: Storage & handling
  Widget _buildStorageHandlingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage & Cylinder Handling',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
          color: Colors.white,
              ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedSafetyCard(
          delay: 0,
          title: 'Safe Storage',
          icon: Icons.inventory_2,
          color: const Color(0xFF22C55E),
          tips: [
            'Store cylinders upright; secure to prevent tipping',
            'Keep away from heat sources and direct sunlight',
            'Never store in basements or enclosed, low-lying spaces',
          ],
        ),
        _buildAnimatedSafetyCard(
          delay: 120,
          title: 'Transport & Use',
          icon: Icons.local_shipping,
          color: const Color(0xFF3B82F6),
          tips: [
            'Use protective caps; avoid rolling cylinders',
            'Check hoses, valves, and regulators regularly',
            'Use soapy water to check for leaks (never a flame)',
          ],
        ),
      ],
    );
  }

  // New: Myths vs Facts section
  Widget _buildMythFactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Myths vs Facts',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
          color: Colors.white,
              ),
        ),
        const SizedBox(height: 12),
        _buildMythFactTile(
          myth: 'If I don’t smell gas, there’s no danger.',
          fact: 'False. Some gases (like CO) are odorless. Rely on detectors.',
          color: const Color(0xFFEF4444),
        ),
        _buildMythFactTile(
          myth: 'Opening one window is enough ventilation.',
          fact: 'Cross-ventilation works best. Open windows on opposite sides.',
          color: const Color(0xFFF59E0B),
        ),
        _buildMythFactTile(
          myth: 'Any spot is fine for a detector.',
          fact: 'Placement depends on gas type. NG rises; LPG sinks.',
          color: const Color(0xFF3B82F6),
        ),
        _buildMythFactTile(
          myth: 'I can test leaks with a lighter.',
          fact: 'Never. Use soapy water or a gas leak detector spray.',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  // New: Myth vs Fact tile helper
  Widget _buildMythFactTile({
    required String myth,
    required String fact,
    required Color color,
  }) {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tips_and_updates, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Myth', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                  Text(
                    myth,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  const Text('Fact', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                  Text(
                    fact,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

// New: small pill chip used in hero banner
class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}