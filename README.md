# sunburstShinyWidget

An R package that provides an interactive sunburst chart as a Shiny [htmlwidget](https://www.htmlwidgets.org/), built on D3.js. Designed for visualizing [OHDSI ATLAS](https://atlas-demo.ohdsi.org/) pathway analysis data — treatment sequences patients follow over time.

## Overview

The sunburst chart renders patient treatment pathways as concentric rings. Each ring represents a step in the treatment sequence, and arc widths are proportional to the number of patients who followed that path. Clicking an arc reveals the full pathway breakdown with patient counts and drop-off statistics.

The included demo data tracks 756 Type 2 Diabetes patients across three drugs (Glipizide, Metformin, Simvastatin), showing how they switch between treatments over up to 5 steps.

## Installation

```r
# Install from source
# install.packages("remotes")
remotes::install_local(".")
```

Or during development:

```r
pkgload::load_all()
```

## Quick Start

```r
library(shiny)
library(bslib)

chartData <- jsonlite::read_json("data/chartData.json")
design <- jsonlite::read_json("data/design.json")

ui <- page_sidebar(
  title = "Sunburst plot",
  sidebar = sidebar(open = FALSE),
  sunburstUI("my_plot")
)

server <- function(input, output) {
  sunburstServer("my_plot", chartData, design)
}

shinyApp(ui, server)
```

Or run the included demo app:

```bash
Rscript app.R
```

## Usage

The package exposes a Shiny module pair and the underlying htmlwidget.

### Shiny Module (recommended)

Provides the full dashboard — sunburst chart, legend, path details table, steps table with CSV download.

```r
# UI
sunburstUI(id)

# Server
sunburstServer(
  id,
  chartData,                             # Pathway analysis data (list from JSON)
  design,                                # Analysis design config (list from JSON)
  btn_font_size = "14px",                # Font size for cohort buttons
  show_colors_in_table = FALSE,          # Colored buttons vs plain text in steps table
  steps_table_export_name = reactive(NULL),  # Custom CSV filename
  n_steps = reactive(5L)                 # Number of pathway steps to display
)
```

### Low-Level Widget

Use the widget directly if you need custom UI:

```r
# UI
sunburstShinyWidgetOutput(outputId, width = "100%", height = "400px")

# Server
output$my_widget <- renderSunburstShinyWidget({
  sunburstShinyWidget(chartData, design)
})
```

## Data Format

The widget expects two JSON structures, typically exported from OHDSI ATLAS pathway analysis results.

### chartData

```json
{
  "eventCodes": [
    { "code": 1, "name": "Glipizide-txp", "isCombo": false },
    { "code": 2, "name": "Metformin-txp", "isCombo": false },
    { "code": 4, "name": "Simvastatin-txp", "isCombo": false },
    { "code": 3, "name": "Glipizide-txp,Metformin-txp", "isCombo": true }
  ],
  "pathwayGroups": [{
    "targetCohortId": 1781666,
    "targetCohortCount": 756,
    "totalPathwaysCount": 366,
    "pathways": [
      { "path": "4-end", "personCount": 115 },
      { "path": "4-2-end", "personCount": 35 }
    ]
  }]
}
```

Event codes use **bitwise encoding** — each base treatment is a power of 2 (1, 2, 4...), and combinations are the bitwise OR of their components (e.g., code `6` = Metformin `2` + Simvastatin `4`). The chart automatically splits combo arcs into individually colored segments.

Pathways are dash-separated event code sequences terminated with `"end"` when shorter than `maxDepth`.

### design

```json
{
  "name": "IQT-Pathways",
  "targetCohorts": [{ "id": 1781666, "name": "T2DM Treatment group" }],
  "eventCohorts": [
    { "id": 1789987, "name": "Glipizide-txp" },
    { "id": 1789986, "name": "Metformin-txp" },
    { "id": 1789985, "name": "Simvastatin-txp" }
  ],
  "combinationWindow": 3,
  "maxDepth": 5
}
```

The sample data comes from the [OHDSI ATLAS demo](https://atlas-demo.ohdsi.org/#/pathways/447/results/71175). Both files originate from a single `PathwayDesignData.json` export — `chartData` is the `data` key and `design` is the `design` key.

## Architecture

```
R (Server)                          JavaScript (Browser)
─────────────                       ────────────────────
sunburstShinyWidget(data, design)
  → htmlwidgets::createWidget(x)
                          ────────→ renderValue(x)
                                      ResultDataConverter.convert()
                                      Sunburst.render()
                          ←──────── Shiny.setInputValue("_chart_data_converted")
                          ←──────── Shiny.setInputValue("_click_data")
callJS() → sendCustomMessage()
                          ────────→ getPathwayGroupDatatable()
                          ←──────── Shiny.setInputValue("_pathway_group_datatable")
```

The JavaScript layer is ported from OHDSI Atlas charting modules and uses D3.js v4 for the partition layout, arc rendering, and color scaling.

## Development

```bash
# Rebuild roxygen docs and NAMESPACE
R -e 'roxygen2::roxygenise()'

# Check the package
R CMD check .

# Install locally
R CMD INSTALL .
```

## License

MIT
