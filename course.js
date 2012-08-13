$(document).ready(function(){
    $("div[slidedata]").each(function(i, div){
        lectureJS.lectures.createLecture($(div));
    });
});

lectureJS = {
    lecture: function (name, data, div) {
        this.name = name;
        this.data = data;
        this.div = div;
        this.fullName = div.attr("id") + name.replace("/", "");

        this.showSlide = function(name, ord, tuple) {
            if (!name)
            {
                this.currentSlide = this.currentSlides = name = data["slides"][0]["name"];
            }



            var that = this;
            $.each(data["slides"], function(key, val){
                if (val["name"] === name)
                {
                    $("#" + that.fullName+val["name"]).css("display", "block");
                    if (tuple && ord===0)
                    {
                        $("#" + that.fullName+val["name"]).css("margin-left", "-420px");
                    }
                    else if (tuple && ord==1)
                    {
                        $("#" + that.fullName+val["name"]).css("margin-left", "0px");
                    }
                    else if (tuple)
                    {
                        $("#" + that.fullName+val["name"]).css("margin-left", "-210px");
                    }

                    $("#iconOf" + that.fullName+val["name"]).addClass("slideIconActive");

                    $("#" + that.fullName+val["name"]).html("");

                    if (val["type"] === "html")
                    {
                        $.ajax({
                            url: that.name+"/"+val["source"],
                            dataType: "text"
                        }).done(function(data){
                                $("#" + that.fullName+val["name"]).html(data);
                            });
                    }
                    else if (val["type"] === "code")
                    {
                        $("<textarea>", {
                            id: "textboxOf" + that.fullName+val["name"],
                            style: "width: 80%; height: 200px;"
                        }).appendTo($("#" + that.fullName+val["name"]));
                        $.ajax({
                            url: that.name+"/"+val["defaultCode"],
                            dataType: "text"
                        }).done(function(data){
                                $("#textboxOf" + that.fullName+val["name"]).val(data);
                            });
                        $("<button>", {
                            text: "Run",
                            click: function(){
                                eval(val["run"] + "($('#" + "textboxOf" + that.fullName+val["name"] + "').val(), " + that.fullName + val["drawTo"] + ")");
                            }
                        }).appendTo($("#" + that.fullName+val["name"]));
                    }
                }
            });
        };

        this.historyStack = new Array();

        this.forward = function() {
            var kam, that = this, ret = true;
            $.each(this.data["slides"], function(key, val){
                if (val["name"] === that.currentSlide)
                {
                    if (!val["next"])
                    {
                        alert("Toto je konec kurzu.");
                        ret = false; return;
                    }
                    kam = val["next"];
                    ret = true; return;
                }
            });
            if (!ret)
            {
                return;
            }
            this.historyStack.push(this.currentSlides);
            $("#" + this.fullName + "backArrow").fadeOut(200);
            $("#" + this.fullName + "forwardArrow").fadeOut(200);
            $.each(this.currentSlides.split(" "), function(key, val){
                $("#"+that.fullName+val).animate({
                    left: "-=100%"
                }, 1000, function() {
                    $("#" + that.fullName+val).css("display", "none");
                    $("#" + that.fullName+val).css("left", "50%");

                    $("#" + that.fullName + "backArrow").css("display", "block");
                    $("#" + that.fullName + "forwardArrow").css("display", "block");
                    if (kam.indexOf(" ")>=0)
                    {
                        $("#" + that.fullName + "backArrow").css("margin-left", "-500px");
                        $("#" + that.fullName + "forwardArrow").css("margin-left", "500px");
                    }
                    else
                    {
                        $("#" + that.fullName + "backArrow").css("margin-left", "-260px");
                        $("#" + that.fullName + "forwardArrow").css("margin-left", "250px");
                    }
                });
                $("#iconOf"+that.fullName+val).removeClass("slideIconActive");
            });

            that.currentSlides = kam;
            $.each(kam.split(" "), function(key, val){
                that.showSlide(val, key, kam.indexOf(" ")>=0);
                that.currentSlide = val;
            });
        };

        this.back = function() {
            var that = this;
            if (this.historyStack.length === 0)
            {
                alert("Toto je začátek kurzu.");
                return;
            }
            $.each(this.currentSlides.split(" "), function(key, val){
                $("#"+that.fullName+val).css("display", "none");
                $("#iconOf"+that.fullName+val).removeClass("slideIconActive");
            });
            this.currentSlides = this.historyStack.pop();
            var that = this;
            $.each(this.currentSlides.split(" "), function(key, val){
                that.showSlide(val);
                that.currentSlide = val;
            });
        };
    },

    lectures: {
        ls: new Array(),  // list of lectures on the page

        createLecture: function(theDiv) {
            var slideList = $("<div>", {
                class: "slideList"
            });
            var innerSlides = $("<div>", {
                class: "innerSlides"
            });

            var name = theDiv.attr("slidedata");
            var ls = this.ls;
            $.getJSON(name + "/desc.json", function(data){
                var newLecture = new lectureJS.lecture(name, data, theDiv);

                $.each(newLecture.data["load"], function(key, val){
                    $.getScript(name + "/" + val);
                });

                $("<div>", {
                    id: newLecture.fullName + "backArrow",
                    class: "arrow-w",
                    click: function() {
                        newLecture.back();
                    },
                    mouseover: function() {
                        $(this).css("border-right-color", "#aaa");
                    },
                    mouseout: function(){
                        $(this).css("border-right-color", "#666");
                    }
                }).appendTo(innerSlides);
                $.each(newLecture.data["slides"], function(key, val){
                    var slideIcon = $("<div>", {
                        id: "iconOf" + newLecture.fullName + val["name"],
                        class: "slideIcon",
                        style: val["icon"] ?
                            "background-image: url('" + name + "/" + val["icon"] + "')" :
                            "background-image: url('icons/" + val["type"] + ".png')"
                    }).appendTo(slideList);
                    var slide = $("<div>", {
                        id: newLecture.fullName+val["name"],
                        class: "slide",
                        style: "display: none"
                    });
                    slide.appendTo(innerSlides);
                });
                $("<div>", {
                    id: newLecture.fullName + "forwardArrow",
                    class: "arrow-e",
                    click: function() {
                        newLecture.forward();
                    }
                }).appendTo(innerSlides);

                slideList.appendTo(theDiv);
                innerSlides.appendTo(theDiv);

                ls.push(newLecture);
                newLecture.showSlide();
            }).error(function() {
                    slideList.html("<p style='position: relative; top: 0.5em'>Course at '" + name + "' is not available.");
                    slideList.appendTo(theDiv);
                });
        }
    }
}