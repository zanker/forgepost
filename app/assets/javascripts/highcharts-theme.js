Highcharts.setOptions({
    colors: ["#8bbc21", "#2f7ed8", "#910000", "#1aadce", "#492970", "#f28f43", "#77a1e5", "#c42525", "#a6c96a"],
    chart: {
        backgroundColor: "transparent",
        borderWidth: 0,
        borderRadius: 15,
        plotBackgroundColor: null,
        plotShadow: false,
        plotBorderWidth: 0,
        resetZoomButton: {
          position: {
            x: 0,
            y: -10
          },
          theme: {
            stroke: "#a6a6a6",
            fill: {
              verticalGradient: { x1: 0, y1: 0, x2: 0, y2: 1 },
              stops: [
                [0, "#FFFFFF"],
                [1, "#a6a6a6"]
              ]
            },
            states: {
              hover: {
                stroke: "#a6a6a6",
                fill: {
                  verticalGradient: { x1: 0, y1: 0, x2: 0, y2: 1 },
                  stops: [
                    [0, "#f2f2f2"],
                    [1, "#f2f2f2"]
                  ]
                }
              }
            }
          }
        }
    },
    title: {
        text: "",
        style: {color: "#f3c90c", font: "14px Helvetica, Arial, sans-serif"}
    },
    subtitle: {
        style: {color: "#f9f9f9", font: "14px Helvetica, Arial, sans-serif"}
    },
    plotOptions: {
        line: {
            animation: false,
            dataLabels: {
                style: {
                    color: "#f3c90c"
                }
            }
        },
        area: {
          animation: false,
        }
    },
    xAxis: {
        gridLineWidth: 0,
        lineColor: "#a6a6a6",
        tickColor: "#a6a6a6",
        labels: {
            y: -10,
            style: {
                color: "#f9f9f9",
                fontWeight: "bold"
            }
        }
    },
    yAxis: {
        alternateGridColor: null,
        minorTickInterval: null,
        gridLineColor: "#8A8A8A",
        minorGridLineColor: "#8A8A8A",
        lineWidth: 0,
        tickWidth: 0,
        labels: {
            style: {
                color: "#ffffff"
            }
        },
        title: {
            style: {
                color: "#f3c90c",
                font: "13px Helvetica, Arial, sans-serif"
            }
        }
    },
    legend: {
        itemStyle: {
            color: "#f9f9f9"
        },
        itemHoverStyle: {
            color: "#a6a6a6"
        },
        itemHiddenStyle: {
            color: "#999"
        }
    },
    labels: {
        style: {
            color: "#CCC"
        }
    },
    tooltip: {
        backgroundColor: "#000000",
        borderWidth: 2,
        crosshairs: true,
        style: {
            color: "#FFF"
        }
    },

    toolbar: {
        itemStyle: {
            color: "#CCC"
        }
    },

    annotations: {
        title: {
            style: {
                color: "red"
            }
        }
    },

    credits: {enabled: false}
});