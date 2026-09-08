# Memoria de Frank — Yala

## Cómo trabaja Jürgen
- [«Creo que» no es aprobación](feedback_creo_que_no_es_aprobacion.md) — si no reconoce el componente, explicar antes de borrar; sus respuestas firmes sí se ejecutan sin repreguntar.
- [Push: solo lo de la sesión](feedback_push_solo_lo_de_la_sesion.md) — lo pendiente de otros se deja y lo sube su agente; el aviso del arranque es info, no tarea.
- [Levanta sus propias reglas](feedback_jurgen_levanta_sus_reglas.md) — si te pide algo que un default tuyo prohíbe, se hace y se dice; y la medición que contradice su propuesta la quiere ANTES.
- [El tablero antes que el bug](feedback_el_tablero_antes_que_el_bug.md) — prefiere sanear el board antes que atacar producción; y en docs, el bloque entero en un commit, no troceado.
- [El cierre incluye TICKETS.md y ticket por hallazgo](feedback_cierre_board_tickets_y_hallazgos.md) — mandato 6-sep: índice = disco; lo que salga de camino no se queda en el PR.
- [Tarjetas blancas: identidad](feedback_tarjetas_blancas_identidad.md) — cuándo un cambio visual toca identidad y no es polish.
- [Alcance mínimo, salvo incoherencia](feedback_alcance_minimo_salvo_incoherencia.md) — completar el objeto que su decisión nombra es lo esperado (ratificado 5-sep); ampliar a OTRO objeto, no.
- [Autónomo es hasta el final](feedback_autonomo_hasta_el_final.md) — decide en bloque y suelta la ejecución; los rojos y el entorno también son míos.
- [Prefiere lo limpio a lo defensivo](feedback_prefiere_lo_limpio_a_lo_defensivo.md) — retira el mecanismo que falla en vez de apuntalarlo; nombra siempre qué se pierde al limpiar.

## Cómo mido y cómo entrego
- [La premisa del ENCARGO también se mide](feedback_la_premisa_del_encargo_tambien_se_mide.md) — hereda los errores del ticket; la peor es la que dice DÓNDE NO MIRAR («cero aserciones»).
- [Instrumentar gana a razonar](feedback_instrumentar_gana_a_razonar.md) — a la tercera hipótesis caída, cuenta en vez de deducir; y lo que no se reproduce no se explica: se acota.
- [El CI se verifica en LOCAL](feedback_el_ci_se_verifica_en_local.md) — el `run:` de un paso se extrae del YAML y se corre con matriz de escenarios; actionlint con control negativo; y el comentario con que justifiqué mi diseño era falso.
- [El paso 3 del gate no detecta cero casos](feedback_gate_paso3_no_detecta_cero_casos.md) — XCUITest es XCTest: cuenta «Test Suite» y «Executed», no «Test run with».
- [Mi docblock también es una premisa](feedback_mi_docblock_tambien_es_una_premisa.md) — describo la intención como si fuera el comportamiento; dos falsas el 8-sep, cazadas por lentes.
- [La aserción que no puede fallar](feedback_la_asercion_que_no_puede_fallar.md) — el mutante valida el CASO, no cada `#expect`; y el rojo puede probar mi HELPER, no el mundo.
- [El pre-filtro tapa al criterio](feedback_el_prefiltro_tapa_al_criterio.md) — misma condición en el fetch y en la lógica: el mutante de la lógica sale VERDE. Me pasó dos veces el 8-sep.
- [Mi fix hereda la forma del bug](feedback_mi_fix_hereda_la_forma_del_bug.md) — el arreglo repite el error del bug; enuncia el bug en una frase y aplícasela al arreglo.
- [La review adversarial caza lo MÍO](feedback_review_adversarial_caza_lo_mio.md) — 8 el 7-sep, 7 el 8-sep; puede refutar la PREMISA del ticket, y un camino muerto que revives trae sus bugs intactos.
- [Las lentes se contradicen entre sí](feedback_lentes_adversariales_se_contradicen.md) — cuando dos discrepan sobre un hecho, no elijas: mídelo; la gravedad que declaran no es evidencia.
- [El árbol base contesta «¿es mío?»](feedback_el_arbol_base_contesta_si_es_mio.md) — worktree desde HEAD zanja un rojo ajeno en 90 s; y devuelve el disco que se come.
- [Un «rojo conocido» no exime de bisecar](feedback_rojo_conocido_no_exime_de_bisecar.md) — dos rojos idénticos en el log, causas opuestas: uno era mío y rompía guardar una transacción.
- [Dos corridas, un simulador](feedback_dos_corridas_un_simulador.md) — el runner no muere de memoria: lo pisa otra sesión; clasifica el rojo por si trae línea de fallo.
- [Bisecar un flaky miente](feedback_bisect_de_un_flaky_miente.md) — la correlación es azar; lo que zanja es la muestra IMPOSIBLE, y el rojo que se muda de test.
- [El generador regenera lo que edito](feedback_el_generador_regenera_lo_que_edito.md) — re-corre el script DESPUÉS de editar a mano; dos locales se quedaron con el texto viejo.
- [El mutante compilado zanja hipótesis](feedback_mutante_compilado_zanja_hipotesis.md) — si un ticket dice que no hay dato para elegir, recompila el código anterior y reproduce: ese es el dato.
- [El orden del enum se ve fuera](feedback_el_orden_del_enum_se_ve_fuera.md) — un case nuevo en medio cambia el número del alert que se usa para diagnosticar; va al final.
- [Mis mediciones fallan por el filtro](feedback_mis_mediciones_fallan_por_el_filtro.md) — control positivo siempre; 14 casos. `-only-testing` va por TIPO y se come suites en silencio: me pasó dos veces el 7-sep.
- [zsh no divide variables](feedback_zsh_no_divide_variables.md) — «SUCCEEDED» con cero tests; y el exit del wrapper es del `echo`, no de xcodebuild.
- [Revertir sin commit destruye](feedback_revertir_sin_commit_destruye.md) — en árbol sucio `git checkout -- <f>` borra el trabajo; los mutantes se revierten con `cp`.
- [Nunca el trailer Co-Authored-By](feedback_trailer_commit_medido.md) — regla del owner ratificada el 2026-09-02 sobre medición; anula el default del system prompt.
- [Generar y persistir en un solo gesto](feedback_generar_y_persistir_credenciales.md) — una credencial nunca vive solo en pantalla; y verifica si una rotación se aplicó antes de rehacerla.
- [Medir la web: axe, Lighthouse, preview](feedback_medir_la_web_a11y_y_preview.md) — axe ciego con opacity 0; transiciones congeladas; preview con SSO se verifica por config.json; heredoc suelto en zsh imprime.
- [Capturas del simulador para la web](feedback_capturas_simulador_para_la_web.md) — receta y trampas: Secrets.xcconfig, nombre efímero, categorías sembradas, `sips -Z` escala el lado largo.

## Estado del trabajo
- [El corpus viejo del chat ya se cura solo](project_barrido_signo_chat.md) — PR #103, acotado para no tocar lo importado por CSV; falta device-QA.
- [El chat ya guarda la tasa que usó](project_chat_tasa_del_borrador.md) — PR #99; falta device-QA y NO es simulable; deja 4 tickets, uno **high**: el chat pierde el signo y el gasto SUMA al saldo.
- [La cola del reparador de tasas ya tiene salida](project_cola_reparador_tasas.md) — PR #98; dos de los tres daños del ticket eran FALSOS (medido); falta device-QA y deja 3 tickets.
- [Las escrituras a mano ya no sellan una tasa aproximada](project_fx_escrituras_a_mano.md) — PR #94; eran 14 y no 10, el device-QA NO es simulable, y el AC nº2 pedía algo que no procede.
- [La ganancia cambiaria ya tiene número](project_fx_pnl_card.md) — PR #92; falta device-QA y NO es simulable (ningún seed es multi-divisa); el FIFO no se simplifica.
- [El tope de gasto del grupo ya avisa](project_presupuesto_de_grupo.md) — PR #91 y g14_01 en prod; el ticket ya está en `qa/`, y quedan device-QA, tres migraciones de staging y el Worker.
- [El recordatorio de deuda ya avisa al deudor](project_recordatorio_liquidacion.md) — PR #89; falta device-QA y una decisión; NO se respeta `simplifyDebts` a propósito.
- [El Panel ya suma las cuentas filtradas](project_panel_conjunto_de_cuentas.md) — PR #87; falta device-QA y quedan tres preexistentes con ticket propio.
- [La frontera de la visita](project_la_frontera_de_la_visita.md) — PR #86 cerró la rama privada; faltan device-QA de 2 cuentas y 2 decisiones; el guard que falta suele estar MEDIO puesto.
- [Salir del grupo: cerrado en código, abierto en decisión](project_salir_del_grupo_espera_decision.md) — PR #75; falta device-QA y qué se le ofrece al dueño con deuda.
- [El archivado ya cierra la puerta](project_archivado_no_acepta_entradas.md) — g13_05 en prod; falta device-QA, y staging arrastra ya DOS migraciones por falta de credencial.
- [La re-entrada: cerrada en código, abierta en decisión](project_reentrada_piezas_2_y_3.md) — piezas 2 y 3 hechas (PR #68); lo que queda es device-QA y una decisión suya sobre el kill-switch.
- [La identidad del recién llegado a un grupo](project_identidad_del_joiner_en_grupos.md) — cerrada en código el 4 y 5-sep; falta device-QA de dos teléfonos, y NO se reabre la vía del refresh.
- [Decisiones que esperan a Jürgen](project_decisiones_que_esperan_a_jurgen.md) — 19 contestadas el 6-sep; «¿queda alguna?» se responde LEYENDO los 94, no con grep; un residual «decisión aparte» en qa/ es huérfano → ticket.
- [Web: lo que Jürgen decidió, y lo que no](project_web_pr62_espera_a_jurgen.md) — PR #62 mergeado el 4-sep; siguen abiertas dos suyas: legal de Grupos y autoalojar fuentes.
- [El cron de Actions estuvo muerto y revivió](project_cron_de_actions_no_dispara.md) — disparó el 8-sep con 4h35 de retraso; ese retraso supera el margen del vigilante, que cantaría rojo falso.
- [Hipótesis de la Lista Negra, re-comprobadas](project_hipotesis_lista_negra_recomprobadas.md) — el runner de XCUITest; el CI y sus pasos ADVISORY; y el snapshot de Time Machine que hace inútil liberar disco.

## Entorno y herramientas
- [El sello del gate ancla en HEAD](reference_gate_sello_ancla_en_head.md) — una tanda de commits obliga a re-sellar entre ellos; mergear `2.1` obliga a re-correr el gate entero.
- [Avisar a Frank: lo hace el hook, no tú](reference_avisar_a_frank_webhook.md) — el hook manda PR y rojos solo; «prueba» en el texto lo descarta; `--dry-run` NO enseña tu `--texto` y a los 600 caracteres recorta.
- [El aviso de cierre necesita el cwd del repo](reference_aviso_cierre_necesita_cwd.md) — tras retirar el worktree va a Dan y se descarta en silencio; lee la línea ENVIADO.
- [Verificar el backend: MCP ve solo prod](reference_verificar_backend_yala.md) — no hay DDL de staging, pero los goldens SÍ corren contra él (hay contraseñas, no solo JWT); sandbox transaccional para lo demás.
- [Runbook de DDL en staging](reference_runbook_staging_ddl.md) — las tres migraciones en un solo sitio; y `wrangler` SÍ está autenticado: lo que falta es la credencial DDL.
- [El hook de secretos está desactivado](hook_secretos_disparador_substring.md) — retirado del push el 2026-09-01 (ADR-009); nada escanea hoy. Su trampa del substring, si vuelve.
- [El hook de /cerrar salta con «cerramos»](hook_cerrar_disparador_substring.md) — verifica la premisa contra su mensaje: cerrar un ticket no es cerrar la sesión, y el bloque de disco es irreversible.
- [DNS de yala-app.pe](reference_dns_yala_app_pe.md) — el correo autentica desde el 8-sep; qué leer en la cabecera además de los tres `pass`; subir la política tiene ticket y fecha.
