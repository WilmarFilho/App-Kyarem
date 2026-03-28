import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Cabeçalho padronizado para telas de autenticação
/// Exibe o logo e nome da aplicação
class AuthHeader extends StatelessWidget {
  final bool isSmall;

  const AuthHeader({super.key, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmall ? 25 : 40),
        child: Column(
          children: [
            SvgPicture.asset(
              'assets/images/meteor.svg',
              width: isSmall ? 60 : 80,
              height: isSmall ? 60 : 80,
            ),
            SizedBox(height: isSmall ? 10 : 16),
            Text(
              'KYAREM EVENTOS',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontWeight: FontWeight.w400,
                fontSize: isSmall ? 42 : 52,
                color: Colors.black,
                height: 1.0,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Área Administrativa',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 14 : 16,
                color: const Color.fromRGBO(0, 0, 0, 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
