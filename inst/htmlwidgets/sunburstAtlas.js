HTMLWidgets.widget({

  name: 'sunburstAtlas',

  type: 'output',

  factory: function(el, width, height) {
    var elementId = el.id
    // TODO: define shared variables for this instance

    return {

      renderValue: function(x) {
        var chartData = x.data;
        var design = x.design;
        console.log(">>> ID: " + elementId);

        /*
        requirejs(['atlascharts/sunburst', 'resultDataConverter'], function (Sunburst, ResultDataConverter) {
          var cartData;
          var plot = new Sunburst();
          var resultDataConverter = new ResultDataConverter();
          //var target = document.querySelector('#plot');
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
/*
          function refreshPlot() {
            //pathwayAnalysisDTO = JSON.parse(document.querySelector("#chartData").value);
            //design = JSON.parse(document.querySelector("#design").value);

            chartData = resultDataConverter.convert(pathwayAnalysisDTO, design);


            chartData.cohortPathways.forEach(pathwayData => {
              plot.render(pathwayData.pathway, target, 600, 600, { split: split, minRadians: 0, colors: chartData.colors });
            });
          }


          document.querySelector("#reload").addEventListener("click", function () {
            refreshPlot();
          });
          refreshPlot();

        });

        */
      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
