# HANDS SANDBOX — Etapas 001–004 (integração em andamento)

Godot 4.x / Android. Preserva o ambiente 3D da Etapa 001, o ragdoll físico da Etapa 002 e a fábrica de objetos da Etapa 003. A Etapa 004 adiciona a fonte nativa Android para rastreamento real via câmera frontal, CameraX e MediaPipe Tasks; sua ativação depende da montagem e validação do plugin Android descritas em `android/README.md`.

## Recursos preservados

- Chão cinza e mesa laranja com materiais de placa de base, iluminação, câmera em primeira pessoa e física.
- Ragdoll amarelo articulado por corpos rígidos e juntas físicas.
- Cubos, esferas, cilindros e blocos de placa de base configuráveis, identificados individualmente e empilháveis; teclas 1–4 continuam criando objetos no desktop.

## Rastreamento de mãos Android

A integração nativa utiliza a câmera frontal real e MediaPipe Hand Landmarker para até duas mãos, com 21 landmarks por mão, lado, confiança e coordenadas normalizadas. A API entrega esses dados pelo singleton `HandsTracking` e pelo sinal `hands_updated`. Frames antigos são descartados após perda temporária; o pequeno indicador 3D muda para verde apenas quando há uma detecção recente.

A integração requer modelo `.task`, AAR de API Godot correspondente à versão, custom Android build, permissão de câmera e teste em dispositivo. Consulte `android/README.md`. Não há fallback de landmarks simulados: em builds sem plugin o rastreamento permanece indisponível. Modelos 3D das mãos e seleção/manipulação de objetos ainda não são implementados; os dados e IDs dos objetos permitem integração posterior.

## Execução

Abra `project.godot` com Godot 4.3+. Desktop continua executando os sistemas físicos existentes, mas não possui hand tracking. Para Android, siga os passos e limitações de `android/README.md`; não considere o rastreamento funcional até validar instalação, permissão, detecção esquerda/direita e perda de sinal em um aparelho real.

## Arquivos novos

- `scripts/input/hand_tracking_bridge.gd` — interface GDScript, emissão de dados e indicador 3D baseado em detecção real.
- `android/plugins/hands_tracking/` — código do plugin Android CameraX/MediaPipe e manifesto.
- `android/download_hand_landmarker_model.sh` — obtém o modelo oficial durante configuração, fora do commit.
- `android/README.md` — dependências, integração e limitações.

Não há modelo binário ou AAR comitados. Isso evita incluir binários não verificados e versões de API incompatíveis.
