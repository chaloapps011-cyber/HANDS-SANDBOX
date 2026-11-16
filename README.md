# HANDS SANDBOX — Etapa 001: Fundação do jogo

Primeira fundação jogável em Godot 4 para Android, com cenário 3D leve e organizado em módulos. O protótipo entrega chão cinza e mesa em tom laranja com padrão de placas e pinos, iluminação/sombras, câmera em primeira pessoa, colisões e blocos rígidos que podem ser empurrados.

## Estrutura

- `scenes/main.tscn` — cena inicial.
- `scripts/world/main_world.gd` — composição do ambiente.
- `scripts/world/floor.gd` — piso estático e colisão.
- `scripts/world/table.gd` — mesa modular com colisores.
- `scripts/player/player_controller.gd` — câmera e locomoção em primeira pessoa.
- `scripts/objects/physical_block.gd` — objeto físico reutilizável.
- `scripts/materials/baseplate.gd` — textura procedural compartilhada.

## Executar

1. Instale Godot 4.3 ou superior.
2. Abra `project.godot` no Godot e execute a cena principal (F6/F5).
3. Desktop: WASD para andar, mouse para olhar; clique na janela para capturar o mouse e Escape para liberar.
4. Tela tátil: arraste no lado esquerdo para andar e no lado direito para olhar. Não há widgets 2D.
5. Android: configure o export template Android no Godot, crie um preset Android e exporte o projeto. O renderer Mobile/Compatibility foi selecionado para aparelhos modestos.

## Limites desta etapa

- VR Box é um visor passivo: esta etapa oferece somente visualização monocular normal. Renderização estereoscópica requer integração XR dedicada e deve ser validada em etapa posterior.
- Não existe hand tracking, mãos virtuais, esqueleto, ragdoll ou interface 3D implementados nesta etapa. A arquitetura separa player, mundo e objetos para permitir integração futura real sem simular recursos ausentes.
- O padrão de placas é gerado localmente em runtime, sem download de assets.

## Validação

Importe e execute no Godot 4.3+; confirme o piso, mesa, blocos, iluminação e controle em desktop/touch. A exportação Android final depende de SDK/JDK e templates configurados no ambiente do desenvolvedor. Nenhuma validação em dispositivo físico foi executada neste commit.
