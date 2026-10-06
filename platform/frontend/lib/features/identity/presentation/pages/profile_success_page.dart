import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../shared/widgets/success_view.dart';

class ProfileSuccessPage extends StatelessWidget {
  const ProfileSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SuccessView(
        title: 'Perfil Atualizado Com Sucesso!',
        message: 'Agora você pode continuar sua jornada financeira!',
        actionLabel: 'Voltar Para Tela Principal',
        onAction: () => context.go(Routes.dashboard),
      ),
    );
  }
}
