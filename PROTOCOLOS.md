# Protocolos de combate — primeira versão

Cada protocolo muda uma decisão de combate e produz um efeito reconhecível. A instalação acontece após cada sala, por clique ou pelas teclas 1, 2 e 3. Protocolos diferentes coexistem. Reinstalar o mesmo protocolo eleva seu nível e soma 1 ao dano do seu efeito; não altera o dano básico do soco.

## Implementados

| Protocolo | Regra inicial | Evolução | Visual |
| --- | --- | --- | --- |
| Curto-Circuito | Três acertos básicos no mesmo inimigo descarregam 1 de dano no outro inimigo mais próximo em até 220 px. O contador é individual; um golpe fatal também pode disparar a descarga. Sem vizinho, o ciclo é consumido com uma faísca. | +1 dano na descarga por nível. | Circuitos cianos no braço, indicadores sobre cada alvo e arco entre inimigos. |
| Rastro Fantasma | Cada esquiva deixa uma silhueta no ponto de partida. Após 0,35 s ela explode, causando 1 de dano por inimigo num raio de 100 px. | +1 dano na explosão por nível. | Silhueta magenta, falhas horizontais e anel de explosão. |
| Sobrecarga | Três golpes básicos que acertam carregam o braço. Cada golpe conta uma vez, mesmo acertando vários inimigos. Uma carga parcial expira após 2,5 s sem acerto. Com três cargas, o próximo acerto libera uma onda frontal de 2 de dano, alcance de 145 px e abertura aproximada de 139°. | +1 dano na onda por nível. | Luzes douradas sobem do braço ao ombro; círculo de prontidão e onda frontal. |

A Sobrecarga totalmente carregada permanece pronta até o próximo acerto ou fim da sala. Sua onda pode atingir novamente o alvo principal: esse dano adicional é intencional. Cada alvo recebe a onda somente uma vez por ativação.

Descargas, ondas e explosões não geram novas cargas ou descargas. Isso permite combinar protocolos sem ciclos de dano recursivos. Curto-Circuito favorece aproximar inimigos antes do terceiro golpe; Rastro favorece esquivar a partir de uma posição ocupada por inimigos; Sobrecarga favorece reservar o acerto carregado para um grupo na frente do jogador.

Trocar de sala preserva instalações e níveis, mas limpa contadores por alvo, cargas parciais/prontas, silhuetas e efeitos pendentes. Morte, vitória e reinício também cancelam efeitos pendentes. Reiniciar remove todos os protocolos. Distância da esquiva, invulnerabilidade e tremor da câmera permanecem como antes.

A instalação após a terceira sala libera a porta para o Cobrador de Memórias. Todos os protocolos chegam ao encontro final; seus dois guardas também permitem aproveitar as descargas entre alvos. Derrotar o chefe e os guardas encerra a tentativa.

## Direção futura, ainda não implementada

- **Quebra-Firewall:** ataque após esquiva rompe defesa e interrompe preparação inimiga.
- **Pulso Magnético:** terceiro golpe puxa inimigos para o impacto; combinação prevista com Curto-Circuito.
- **Reciclagem de Energia:** derrotas deixam cargas temporárias que beneficiam a próxima esquiva; combinação prevista com Rastro Fantasma.
- **Eco de Impacto:** golpe carregado deixa uma marca que repete parte do dano; combinação prevista com Sobrecarga.
- **Protocolo de Emergência:** proteção contra dano fatal uma vez por sala, com vida baixa e escudo breve.

Valores de alcance, atraso e janela de combo estão centralizados em `scripts/combat_protocols.gd`. Balanceamento ainda depende da avaliação jogando.
