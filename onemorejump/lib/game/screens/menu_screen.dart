import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GladiatorGame>(
      builder: (context, game, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Arka plan resmi
              Positioned.fill(
                child: Image.asset(
                  'assets/unnamed.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              // Karartma
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(100),
                        GameConstants.primaryDark.withAlpha(230),
                      ],
                    ),
                  ),
                ),
              ),

              // İçerik
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Logo
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: GameConstants.gold.withAlpha(60),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: GameConstants.primaryDark.withAlpha(200),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: GameConstants.gold, width: 3),
                                ),
                                child: Icon(
                                  Icons.gavel,
                                  size: 80,
                                  color: GameConstants.gold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Alt yazı
                        Text(
                          'Kendi gladyatör okulunu yönet',
                          style: TextStyle(
                            fontSize: 14,
                            color: GameConstants.textMuted,
                            letterSpacing: 1,
                          ),
                        ),

                        const Spacer(),

                        // Başla butonu
                        GestureDetector(
                          onTap: () => game.startGame(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  GameConstants.bloodRed,
                                  GameConstants.buttonPrimary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: GameConstants.gold.withAlpha(100)),
                              boxShadow: [
                                BoxShadow(
                                  color: GameConstants.bloodRed.withAlpha(100),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'OYUNA BAŞLA',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: GameConstants.textLight,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
