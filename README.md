# HANDS SANDBOX — Etapa 003: Objetos e construção

Projeto Godot 4.x para Android, com as etapas anteriores preservadas e um sistema modular para criar e empilhar objetos físicos.

## Sistema de objetos

- Formas disponíveis: cubo, esfera, cilindro e bloco com material de placa de base.
- Cada instância é um `RigidBody3D` com gravidade, colisão, massa, atrito e elasticidade configuráveis.
- Tamanho, rotação, posição e cor podem ser definidos na criação; objetos mantêm corpo físico e identificação únicos (`sandbox_object_id`), também agrupados em `sandbox_objects`.
- O material de placa é procedural e compartilhado com o piso/mesa; os demais materiais permitem escolher cor e rugosidade.
- Ao iniciar há uma pequena pilha de demonstração de quatro formas.

## Criar objetos

- Teclas `1`, `2`, `3` e `4` criam, respectivamente, cubo, esfera, cilindro e bloco de placa de base à frente da câmera; o objeto cai e colide com o cenário.
- Código/sistemas posteriores podem criar objetos chamando `spawn_physical_object(shape_type, posição, rotação, tamanho, cor, massa, atrito, elasticidade, usar_placa)` no nó do mundo. Os tipos estão em `PhysicalObjectModule.ShapeType` em `scripts/objects/physical_object.gd`.
- A fábrica é uma API de criação, não uma GUI; não há controles 2D nem hand tracking nesta etapa. Em aparelhos sem teclado, a criação pode ser chamada por código até ser conectada a um input apropriado em uma etapa futura.

## Estrutura relevante

- `scripts/objects/physical_object.gd` — forma, renderização, identificação e parâmetros físicos de cada objeto.
- `scripts/world/main_world.gd` — fábrica pública e demonstração de empilhamento.
- `scripts/objects/ragdoll.gd` — ragdoll articulado da Etapa 002.
- `scripts/world/floor.gd` e `scripts/world/table.gd` — cenário da Etapa 001, sem mudanças.

## Executar e validar

Abra `project.godot` no Godot 4.3+ e execute a cena principal. Verifique a pilha demonstrativa, colisões no piso/mesa e criação pelas teclas `1`–`4`. Confirme que cada objeto cai, colide, empilha e pode ser identificado por `get_meta("sandbox_object_id")`. A exportação Android e desempenho precisam ser confirmados no dispositivo alvo; mantenha a quantidade de corpos rígidos moderada.

## Limites

Sem hand tracking, GUI 2D ou mecânicas adicionais. A fundação visual e controles das etapas anteriores permanecem preservados.
