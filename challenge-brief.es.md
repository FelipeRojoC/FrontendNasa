# NASA Space Apps Challenge 2026: Armonización de hotspots de MODIS y VIIRS

> **Versión en español.** El original para agentes/LLM es `challenge-brief.en.md` (inglés). Si hay dudas de interpretación, manda el original.
>
> **Fuentes combinadas en este archivo**
> 1. Página oficial del desafío (pestañas Details y Resources): https://www.spaceappschallenge.org/2026/challenges/modis-and-viirs-hot-spots/ (leída el 2026-11-14)
> 2. Audio de presentación de la autora del desafío (4:51), transcrito con Whisper y corregido a mano. Archivo original: `2026 Challenge Harmonization of MODIS and VIIRS Hot Spots.mp3`
>
> **Quién habla en el audio:** Marina Compagnucci, CONAE (Comisión Nacional de Actividades Espaciales, Argentina), grabado en el Centro Espacial Teófilo Tabanera, Córdoba, Argentina.
>
> **Cómo usar este archivo:** las secciones 1-8 son una síntesis estructurada de ambas fuentes. La sección 9 es la transcripción completa del audio, traducida. Si un resumen y una fuente no coinciden, manda la fuente. La sección 7 lista las diferencias entre la página oficial y el audio.

---

## 1. Metadatos (página oficial)

| Campo | Valor |
|---|---|
| Título del desafío | Harmonization of MODIS and VIIRS Hot Spots (Armonización de hotspots de MODIS y VIIRS) |
| Evento | 2026 NASA Space Apps Challenge |
| Dificultad | Intermedia, Avanzada |
| Materias | Ciencias de la Tierra (Earth Science), Software |
| Crédito de la foto del desafío | CONAE (Comisión Nacional de Actividades Espaciales de Argentina) |
| Pestañas de la página | Details, Resources, Teams |

## 2. Resumen en un párrafo

Construir una **aplicación web** que entregue un **calendario armonizado de actividad de quemas** basado en hotspots (puntos calientes) de incendio activo. Une el largo registro histórico de **MODIS** (Terra/Aqua, desde los 2000 hasta hoy, en retiro) con el registro más nuevo y detallado de **VIIRS**, de modo que el sensor de origen deje de importar. Los usuarios (equipos de respuesta a emergencias, científicos, gestores de tierras, bomberos) eligen un área de interés y un rango de fechas, y ven y descargan analíticas y visualizaciones de actividad de fuego: qué meses y años tuvieron más fuego y cómo se compara el mes actual con la mediana histórica.

## 3. Planteamiento del problema

- Los satélites han rastreado hotspots de incendio activo por **más de dos décadas**.
- El registro está **dividido entre sensores cuyos datos no se pueden comparar directamente**. MODIS y VIIRS difieren en:
  - resolución espacial
  - sensibilidad
  - horario de observación (horas de paso del satélite)
- Los sensores MODIS (en los satélites Terra y Aqua) **se acercan al final de su vida operativa** y están siendo reemplazados por VIIRS.
- Sin armonización, los gestores de incendios no tienen una imagen consistente de **cuándo y dónde hubo quemas**, y parte del registro histórico se pierde en la práctica.
- A medida que aumentan la frecuencia y la intensidad de los incendios, los gestores necesitan un calendario de hotspots actualizado y consistente para ver rápido, por ejemplo, **qué mes y qué años tuvieron la mayor actividad de fuego**, y para **comparar el mes actual con la mediana histórica** de un área seleccionada.

## 4. Objetivos (oficiales)

Desarrollar un **calendario armonizado de actividad de quemas** basado en hotspots de incendio activo, dentro de una aplicación web, que combine la extensa serie histórica de MODIS con la continuidad y el mayor detalle de VIIRS, para entregar una **serie temporal consistente de actividad de hotspots**.

Enfoque sugerido en **dos partes**:

### Parte 1: Armonización de hotspots
- Hacer comparables los hotspots de MODIS y VIIRS para que, al terminar esta fase, "el sensor de origen ya no importe y el foco sean los patrones, las tendencias y las anomalías".

### Parte 2: Aplicación web
- Recibe como entrada los datos de hotspots armonizados.
- El usuario puede **elegir una región y un rango de fechas específico**, y luego **descargar analíticas y visualizaciones** de la actividad de fuego.
- Incluye un **calendario de actividad de quemas** que muestre el **número de hotspots detectados desde principios de los 2000 hasta hoy**, construido sobre el dataset armonizado. Debería mostrar:
  - qué épocas del año tienen más incendios
  - qué años tuvieron más actividad de quemas
  - cómo se compara un incendio actual con los anteriores
- Opcional: **rampas de color** que representen similitudes y diferencias en el conteo de hotspots entre meses (accesibles e intuitivas).
- Opcional: un **CSV descargable** con los hotspots detectados en una búsqueda.

> El audio agrega: el usuario podría "elegir un día específico, una región particular, y visualizar su historial de actividad de fuego, y probablemente obtener algunas analíticas". Los equipos también pueden tomar un **enfoque completamente distinto**, que es "igual de bueno".

## 5. Consideraciones posibles (oficiales; opcionales, no obligatorias)

- **Público objetivo:** equipos de alerta temprana y respuesta a emergencias, científicos, gestores de tierras, bomberos.
- **Interactividad:** por ejemplo, un mapa donde el usuario **dibuje el área de interés**, o una opción para **ingresar latitud y longitud**.
- **Rampas de color accesibles.**
- Un **calendario de quemas** como vista central.
- Concentrarse en pocos índices y cifras clave, presentados como visualizaciones de datos, por ejemplo:
  - **comparaciones históricas**, incluidas **anomalías respecto de promedios multianuales**
  - **número de incendios detectados y reportados**
- La página dice que podrían agregarse más recursos antes del hackathon.

## 6. Datos y recursos

### Oficiales (pestaña Resources)
- **FIRMS (NASA Earthdata): Fire Information for Resource Management System**: https://www.earthdata.nasa.gov/data/tools/firms
  - Da acceso a imágenes satelitales globales casi en tiempo real, incendios/hotspots activos y productos relacionados (ubicación, extensión e intensidad de la actividad de incendios). La página sugiere "armonizar los hotspots de NASA Earthdata FIRMS".
- Aviso en la página: NASA no respalda a entidades no gubernamentales de EE. UU.; en sitios no gubernamentales de EE. UU., los participantes deben cumplir los términos de uso de datos de ese sitio.

### Del audio
- Usar el sitio de NASA FIRMS, más recursos de CONAE y de otras agencias espaciales.

### Otros enlaces oficiales
- Preguntas frecuentes para participantes: https://www.spaceappschallenge.org/resources/participant-faqs/
- Guías y recursos para participantes: https://www.spaceappschallenge.org/resources/
- Space Apps Connect (preguntas): https://github.com/nasa/spaceapps

## 7. Diferencias y vacíos entre las fuentes

- **Audio vs. página sobre la pérdida de datos:** el audio dice que sin un método de comparación "casi 10 años de información histórica se perderán" (transcripción de baja confianza; verificar escuchando el audio). La página oficial no da esa cifra; solo dice que el registro abarca "más de dos décadas".
- **Solo en el audio:** casos de uso de alerta temprana (incendios, inundaciones, derrames de petróleo), el ejemplo de Chilecito, La Rioja (Argentina, julio de 2026) y la frase de que los equipos pueden usar un enfoque completamente distinto.
- **Solo en la página:** dificultad, materias, descarga de CSV, rampas de color, comparación de anomalías contra la mediana histórica, idea de dibujar el área en un mapa, accesibilidad.
- **No especificado en ninguna fuente:** el método de armonización, el stack tecnológico, el alcance geográfico, el rango exacto de fechas, los criterios de evaluación y los productos o endpoints concretos de FIRMS a usar (por ejemplo, qué archivos de MODIS y VIIRS, qué filtros de confianza). Quedan a decisión del equipo.

## 8. Contexto del dominio

- Regímenes de fuego: algunos ecosistemas necesitan fuego periódico, pero los cambios en intensidad, extensión y frecuencia dañan el clima, la sociedad y la biodiversidad, y ponen en peligro vidas y bienes. Los incendios son cada vez más de origen humano.
- "Actividad de quemas" incluye incendios forestales en vegetación natural y bosques, además de fuegos de origen humano por agricultura, limpieza de terrenos, quema de residuos y actividades industriales.
- La detección se basa principalmente en mediciones de **infrarrojo medio (MIR) e infrarrojo térmico (TIR)**, donde la combustión activa produce su señal más fuerte. Los sensores térmicos también detectan erupciones volcánicas y calor industrial como las antorchas de gas.
- Durante un incendio activo, los hotspots ayudan a los científicos a ubicar dónde es más probable que haya fuego y a esperar el paso de un satélite. Luego las imágenes aportan detalle y, al final, un mapa del área quemada. Los hotspots siguen siendo útiles para juzgar dónde el fuego puede o no propagarse.
- Los modelos climáticos proyectan que el clima propicio para incendios será más común e intenso.
- Audio: el equipo de CONAE da alerta temprana y respuesta a emergencias por eventos que duran de días a semanas. **Casi la mitad son incendios.**

### Glosario
| Término | Significado |
|---|---|
| MODIS | Moderate Resolution Imaging Spectroradiometer, en Terra y Aqua. Registro largo, en retiro. |
| VIIRS | Visible Infrared Imaging Radiometer Suite. Sensor sucesor, más detalle, continuidad. |
| Hotspot | Píxel detectado por satélite con alta probabilidad de incendio activo. |
| FIRMS | Fire Information for Resource Management System de NASA. |
| TIR / MIR | Bandas de infrarrojo térmico / medio usadas para detectar incendios activos. |
| AOI | Área de interés seleccionada por el usuario. |
| Calendario de actividad de quemas (de fuego) | Vista tiempo-por-región del conteo de hotspots que muestra patrones estacionales, anomalías y tendencias. |
| CONAE | Comisión Nacional de Actividades Espaciales, la agencia espacial de Argentina. |

---

## 9. Transcripción completa del audio (traducida al español)

El audio original está en inglés; el texto en inglés corregido está en `challenge-brief.en.md`. Frases de menor confianza: "visualizar su historial de actividad de fuego" (la transcripción cruda decía "fire duty history") y "casi 10 años".

Hola, soy Marina Compagnucci de la CONAE, la Agencia Espacial Argentina. En este momento estamos en el Centro Espacial Teófilo Tabanera, ubicado en Córdoba, Argentina. Soy autora del desafío llamado Armonización de hotspots de MODIS y VIIRS.

Tengo el privilegio de trabajar con un equipo de científicos que brindan alerta temprana y respuesta a emergencias ante diversos eventos que ocurren alrededor del mundo. Esos eventos son incendios, inundaciones y derrames de petróleo, que pueden durar desde unos pocos días hasta incluso semanas. Casi la mitad de esas emergencias son incendios. Ya sean incendios forestales en áreas boscosas o incendios de origen humano por actividades agrícolas, industriales o de limpieza de terrenos.

En el caso de incendios en curso, estos científicos usan hotspots satelitales para monitorearlos y saber dónde están las mayores probabilidades de incendios activos. Pero hay otra herramienta poderosa que también usa hotspots, en este caso integrando datos históricos y recientes provenientes de los hotspots. Esta herramienta se llama Calendario de Actividad de Quemas, también Calendario de Actividad de Fuego, y ayuda a visualizar tendencias, anomalías o incluso patrones estacionales en el comportamiento del fuego. Por ejemplo, te muestra cuántos hotspots tiene un área en particular a lo largo de distintos años. Consideren que los modelos climáticos proyectan que el clima propicio para incendios será más común e intenso, así que estas herramientas, tanto el calendario como los hotspots, son muy importantes.

Las imágenes que están viendo fueron procesadas para un incendio que ocurrió en Chilecito, La Rioja, Argentina, en julio de 2026. Al comienzo del evento, los científicos usaron hotspots para inspeccionar el área y esperar el paso de un satélite. Luego, con las imágenes, pueden trabajar con más detalle, pero los hotspots siguen siendo importantes, ya que pueden identificar áreas donde los incendios podrían o no propagarse. Hacia el final del evento, tienen más detalle del área quemada.

Ahora sí hemos llegado al núcleo del desafío. Aunque MODIS y VIIRS han rastreado hotspots de incendio activo por más de dos décadas, el problema es que este registro está dividido entre dos sensores distintos cuyos datos no se pueden comparar directamente. ¿Por qué? Porque tienen distinta resolución espacial, distintas sensibilidades e incluso distintos horarios de observación. Y para empeorar las cosas, los sensores MODIS están terminando su vida operativa y siendo reemplazados por sensores VIIRS, así que si no existe un método para comparar sus datos, casi 10 años de información histórica se perderán, y los gestores de incendios se quedarán sin un calendario histórico que les diga cuándo y dónde han ocurrido incendios.

Por eso necesitamos su ayuda con este problema real y urgente. Su desafío, si deciden aceptarlo, es desarrollar un calendario armonizado de actividad de quemas que combine la extensa información histórica de MODIS con la continuidad y el mayor detalle de VIIRS, de modo que al final de este desafío tengamos una serie temporal consistente de actividad de hotspots. Todo esto en una aplicación web. Consideren usar el sitio web de NASA FIRMS y los recursos de nuestra agencia y de otras agencias para abordar este desafío.

Cuando pensamos el desafío, lo concebimos con dos partes para abordarlo. La primera es la armonización de hotspots de MODIS y VIIRS, de modo que al final de esta fase no importe si un hotspot vino de un sensor o del otro. El foco real está en las tendencias, anomalías y patrones que revelan.

La segunda parte es el desarrollo de la aplicación web que toma estos hotspots como entrada y los pone en un calendario, de modo que el usuario, por ejemplo, pueda elegir un día específico, una región particular, y visualizar su historial de actividad de fuego, y probablemente obtener algunas analíticas. O quizás ustedes y su equipo deciden abordar este desafío de una manera completamente distinta, y es igual de bueno.

Así que realmente esperamos con muchas ganas lo que su equipo se les ocurra. Saludos y mucha suerte.
