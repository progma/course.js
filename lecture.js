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

        this.showSlide = function(name) {
            if (!name)
            {
                this.currentSlide = this.currentSlides = name = data["slides"][0]["name"];
            }
            var that = this;
            $.each(data["slides"], function(key, val){
                if (val["name"] === name)
                {
                    $("#" + that.fullName+val["name"]).css("display", "inline-block");
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
            var kam, that = this;
            $.each(this.data["slides"], function(key, val){
                if (val["name"] === that.currentSlide)
                {
                    if (!val["next"])
                    {
                        alert("Toto je konec kurzu.");
                        return;
                    }
                    kam = val["next"];
                }
            });
            this.historyStack.push(this.currentSlides);
            $.each(this.currentSlides.split(" "), function(key, val){
                $("#"+that.fullName+val).css("display", "none");
            });

            this.currentSlides = kam;
            $.each(kam.split(" "), function(key, val){
                that.showSlide(val);
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
            });
            this.currentSlides = this.historyStack.pop();
            var that = this;
            $.each(this.currentSlides.split(" "), function(key, val){
                that.showSlide(val);
                that.currentSlide = val;
            });
        };

        this.hideAll = function() {
            $(".slide").css("display", "none");
            $(".slideIconActive").removeClass("slideIconActive");
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
                    class: "arrow-w",
                    click: function() {
                        newLecture.back();
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