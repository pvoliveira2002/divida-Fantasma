# Dívida Fantasma — Demo de Combate

Protótipo jogável de ação roguelite cyberpunk em 2D isométrico. Esta primeira demo valida movimento, ataque, esquiva, dois comportamentos inimigos e um ciclo completo de vitória ou derrota.

## Como executar no editor

1. Abra `tools/godot/4.7.2/Godot_v4.7.2-stable_win64.exe`.
2. Importe `project.godot`, caso o projeto ainda não apareça na lista.
3. Pressione **F5**.

## Controles

- **WASD:** mover.
- **Clique esquerdo:** atacar na direção do mouse.
- **Espaço:** atacar na direção atual.
- **Shift ou Ctrl:** esquivar.
- **R:** reiniciar após vitória ou derrota.

## Objetivo da demo

Elimine o perseguidor laranja e o atirador roxo. Os avisos vermelhos indicam ataques iminentes. A esquiva concede invulnerabilidade durante o impulso. O alvo azul serve apenas para treinamento e não conta para a vitória.

## Exportação para Windows

O preset `Windows Desktop` gera `build/windows/DividaFantasma.exe`. A exportação exige os templates oficiais correspondentes ao Godot 4.7.2.

O build atual pode ser iniciado diretamente por `build/windows/DividaFantasma.exe`.

## Estado técnico

Consulte `STATUS_PROJETO.md` para funcionalidades, decisões, testes e problemas conhecidos.

