HTMLWidgets.widget({

  name: 'sunburstAtlas',

  type: 'output',

  factory: function(el, width, height) {
    var elementId = el.id;
    document.getElementById(elementId).widget = this;
    console.log(">>>>> init starts");
    var lodash = _;
    var d3tip = d3.tip;

    var Chart = ChartModule(d3, lodash, d3tip);
    var Sunburst = SunburstModule(d3, Chart);

    var util = utilModule(d3);

    var ResultDataConverter = resultDataConverterModule(d3, util);

    var Sunburst = SunburstModule(d3, Chart);

    console.log(">>>>> init ends");
    // TODO: define shared variables for this instance

    return {

      renderValue: function(x) {
        //var chartData = x.data;
        var pathwayAnalysisDTO = x.data;
        var design = x.design;
        var dispatch_ = d3.dispatch("mouseover","mouseleave","click");
        console.log(">>> ID: " + elementId);

        function click(d,i, data) {
          console.log(">>> click event -- i: " + i)
          console.log(">>> click event -- d: " + d)
          var sequenceArray = d.ancestors().reverse();
          sequenceArray.shift(); // remove root node from the array

          dispatch_.call("click", sequenceArray.map(
            function(d) {

              Shiny.setInputValue(
                elementId + "_click_data",
                {
                  d: d.data,
                  i: i,
                  data: data
                },
                sequenceArray,
                {priority: "event"}
              );
              return d.data.name
            }
          ));
        }

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
                nodeClone.data = { name: (1 << i).toString() };
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
            //pathwayAnalysisDTO = JSON.parse(document.querySelector("#chartData").value);
            //design = JSON.parse(document.querySelector("#design").value);

            chartData = resultDataConverter.convert(pathwayAnalysisDTO, design);

            chartData.cohortPathways.forEach(pathwayData => {
              var options = { split: split, minRadians: 0, colors: chartData.colors,
                onclick: click
              };



              plot.render(pathwayData.pathway, target, 600, 600, options);
            });
          }

          /*
          document.querySelector("#reload").addEventListener("click", function () {
            refreshPlot();
          });
          */
          refreshPlot();

        //});

      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
