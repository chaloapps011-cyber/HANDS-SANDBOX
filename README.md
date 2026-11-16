# HANDS SANDBOX — Etapa 002: Sistema de ragdoll

Projeto Godot 4.x para Android, com a fundação da Etapa 001 preservada e um sistema de ragdoll humanoide articulado por física.

## Etapa 002

- Boneco amarelo composto por cabeça, tronco, pelve, braços, antebraços, mãos, coxas, pernas e pés, usando cápsulas arredondadas.
- Cada segmento é um `RigidBody3D` com massa própria, gravidade do mundo, colisão, amortecimento e material físico.
- `ConeTwistJoint3D` conecta segmentos com limites de balanço e torção; segmentos vizinhos ignoram colisão para evitar conflito nas juntas, mas continuam colidindo com o cenário e demais objetos.
- Um ragdoll é adicionado ao iniciar, fora da mesa; a função `spawn_ragdoll(at: Vector3)` permite criar múltiplos exemplares com física independente.
- `apply_impact(impulse, world_position)` oferece um ponto de entrada para aplicar um impacto ao segmento mais próximo.

## Estrutura relevante

- `scripts/objects/ragdoll.gd` — construção do corpo, cápsulas físicas, juntas e entrada de impacto.
- `scripts/world/main_world.gd` — composição do mundo e fábrica pública `spawn_ragdoll`.
- `scenes/main.tscn` — cena inicial da Etapa 001, mantida sem alterações.

## Executar e validar

Abra `project.godot` no Godot 4.3+ e execute a cena principal. Verifique que o ragdoll amarelo cai e repousa no chão, que os segmentos permanecem ligados, e que o chão, mesa e blocos da Etapa 001 continuam presentes. Para testar novos exemplares, chame `spawn_ragdoll(Vector3(x, 0, z))` no nó do mundo. Para impactos, chame `apply_impact(Vector3(0, 0, -4), ponto_global)` no ragdoll.

A quantidade de corpos rígidos por ragdoll é limitada para desempenho em Android; evite instanciar muitos simultaneamente em aparelhos modestos. A execução/exportação em dispositivo Android ainda precisa ser validada com o SDK e templates locais.

## Fora do escopo

Sem sangue, desmembramento, animação falsa, hand tracking ou alterações no piso, mesa, iluminação e controles da Etapa 001. Cada parte é realmente simulada pela física, não é uma pose animada.
