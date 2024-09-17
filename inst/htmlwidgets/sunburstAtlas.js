HTMLWidgets.widget({

  name: 'sunburstAtlas',

  type: 'output',

  factory: function(el, width, height) {
    var elementId = el.id;
    document.getElementById(elementId).widget = this;
    console.log("init starts");
    var lodash = _;
    var d3tip = d3.tip;

    var Chart = ChartModule(d3, lodash, d3tip);
    var Sunburst = SunburstModule(d3, Chart);

    var util = utilModule(d3);

    var ResultDataConverter = resultDataConverterModule(d3, util);

    var Sunburst = SunburstModule(d3, Chart);

    var helpers = new Helpers(d3);

    var initialized = false;

    console.log("init ends");

    return {

      getPathwayGroupDatatable: function(params) {
        console.log("method: getPathwayGroupDatatable");

        var pathLength = params.pathLength;
        var pathwayGroups = params.pathwayAnalysisDTO.pathwayGroups;

        p_groups = Object.entries(pathwayGroups).reduce((acc, [key, value]) => {
          acc[key] = getPathwayGroupDatatable(value, params.pathLength);
          return acc;
        }, {});

        Shiny.setInputValue(
          elementId + "_pathway_group_datatable",
          p_groups,
          {
            priority: "event"
          }
        );

      },

      renderValue: function(x) {
        if (!initialized) {
          initialized = true;
          document.getElementById(elementId).widget = this;

          if (HTMLWidgets.shinyMode) {
            var fxns = ['getPathwayGroupDatatable'];

            var addShinyHandler = function(fxn) {
              return function() {
                Shiny.addCustomMessageHandler(
                  "sunburstAtlas:" + fxn, function(message) {
                    var el = document.getElementById(message.id);
                    if (el) {
                      el.widget[fxn](message);
                    }
                  }
                );
              }
            };

            for (var i = 0; i < fxns.length; i++) {
              addShinyHandler(fxns[i])();
            }
          }
        }

        var pathwayAnalysisDTO = x.data;
        var design = x.design;
        var dispatch_ = d3.dispatch("mouseover", "click");
        console.log(">>> ID: " + elementId);

        // Dimensions of sunburst
        // https://github.com/timelyportfolio/sunburstR/blob/master/inst/htmlwidgets/sunburst.js#L35C61-L35C67
        var width = el.getBoundingClientRect().width;
        var height = el.getBoundingClientRect().height - 70;
        var radius = Math.min(width, height) / 2;
        console.log(">>> width: " + width + ", height: ", +height)

        var plot = new Sunburst();
        var resultDataConverter = new ResultDataConverter();
        var target = document.getElementById(elementId);

        function split(node) {

          if (isNaN(node.data.name)) {
            return [node];
          };

          let splitNodes = [...Number.parseInt(node.data.name).toString(2)].reverse().reduce((result, bit, i) => {
            if (bit == "1") {
              let nodeClone = Object.assign({}, node);
              nodeClone.data = {
                name: (1 << i).toString()
              };
              result.push(nodeClone);
            }
            return result;
          }, [])

          const bandWidth = (node.y1 - node.y0) / splitNodes.length;

          return splitNodes.map((node, i) => {
            node.y0 = node.y0 + (i * bandWidth);
            node.y1 = node.y0 + bandWidth;
            return node;
          })

        }

        function refreshPlot() {

          chartData = resultDataConverter.convert(pathwayAnalysisDTO, design);
          chartData.eventCohorts.forEach(event => {
            event.color = chartData.colors(event.code);
          });

          Shiny.setInputValue(
            elementId + "_chart_data_converted",
            chartData,
            {
              priority: "event"
            }
          );

          function click_helper(d, i) {
            helpers.click(d, i, chartData, chartData.colors, elementId)
          };

          function tooltip_helper(d) {
            return tooltipBuilder(d, chartData, chartData.colors);
          };

          chartData.cohortPathways.forEach(pathwayData => {
            var options = {
              split: split,
              minRadians: 0,
              colors: chartData.colors,
              onclick: click_helper,
              tooltip: tooltip_helper
            };

            plot.render(pathwayData.pathway, target, width, height, options);

          });
        }

        refreshPlot();

      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
