(function basic_bars(container, horizontal) {

    var
    horizontal = (horizontal ? true : false), // Show horizontal bars
    data = [],                                  // First data series
    point,                                    // Data point variable declaration
    i, j;

    // Load patern of takataka.
    function loadFile(filePath) {
        var httpObj = new XMLHttpRequest();
        httpObj.open('GET', filePath, false);
        httpObj.send(null);

        return httpObj.responseText;
    }

    var text = loadFile('http://ie.u-ryukyu.ac.jp/~e105704/programming4/takataka_data.txt');
    var array_string = text.split('\n');

    // Cut redundant words.
    Array.prototype.uniq = function() {
        var
        o = {},
        i,
        l = this.length,
        r = [];

        for (i=0; i<l; i++) { o[this[i]] = this[i] };
        for (i in o) { r.push(o[i]) };

        return r;
    }
    var uniq_string = array_string.uniq();

      // Initialize pattern_count[ ], pattern_name[ ].
    var pattern_count = [uniq_string.length];
    var pattern_name = [uniq_string.length];
    for (i=0; i<uniq_string.length - 1; i++) {
        pattern_count[i] = 0;
        pattern_name[i] = 'taka' + String(i);
    };

    // Count redundant patern.
    for (i=0; i<array_string.length - 1; i++) {
        for (j = 0; j < uniq_string.length - 1; j++) {
            if (array_string[i] == uniq_string[j]) {
                pattern_count[j] = pattern_count[j] + 1;
            }
        }
    }

    console.log(pattern_count);

    for (i = 0; i < pattern_count.length; i++) {
        point = [Math.ceil(pattern_count[i]), i];
        data.push(point);
    };

    // Draw the graph
    Flotr.draw(
        container,
        [data],
        {
            bars : {
                show : true,
                horizontal : horizontal,
                shadowSize : 0,
                barWidth : 0.5
            },
            mouse : {
                track : true,
                relative : true,
            },
            xaxis : {
                title : 'A frequency',
                min : 0
            },
            yaxis : {
                noTicks : uniq_string.length,
                tickFormatter : function(y) {
                    var y = parseInt(y);
                    return pattern_name[y % uniq_string.length];
                },
                min : 0,
                autoscaleMargin : 1,
                title : 'Patern of takataka'
            },
            HtmlText : false,
            legend : {
                postion : 'nw'
            }
        }
    );

    Flotr.EventAdapter.observe(container,'flotr:click',
                               function(position) {
                                   console.log(position.x + '  ' + position.y);
                                   for (i=0; i<uniq_string.length; i++) {
                                       if ((position.x <= pattern_count[i]) && (parseFloat(i)-0.2 < position.y) && (position.y < parseFloat(i)+0.2)){
                                       console.log(pattern_name[i]);
                                       }
                                   }
                               } );

})(document.getElementById("graph"),true);
