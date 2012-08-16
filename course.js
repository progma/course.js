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

        this.showSlide = function(name, order, isThereSecond) {
            if (!name)
            {
                this.currentSlide = this.currentSlides = name = data["slides"][0]["name"];
            }

            var that = this;
            $.each(data["slides"], function(key, slide){
                if (slide.name === name)
                {
                    if (isThereSecond && order===0)
                    {
                        slide.div.css("margin-left", "-440px");
                    }
                    else if (isThereSecond && order==1)
                    {
                        slide.div.css("margin-left", "1px");
                    }
                    else
                    {
                        slide.div.css("margin-left", "-210px");
                    }

                    slide.iconDiv.addClass("slideIconActive");
                    slide.div.css("display", "block");
                    slide.div.css("left", "150%");
                    slide.div.animate({
                    	left: "-=100%"
                    	}, 1000);
                    slide.div.html("");

                    if (slide.type === "html")
                    {
                        $.ajax({
                            url: that.name+"/"+slide.source,
                            dataType: "text"
                        }).done(function(data){
                                slide.div.html(data);
                            });
                    }
                    else if (slide.type === "code")
                    {
                        $("<textarea>", {
                            id: "textboxOf" + that.fullName+slide.name,
                            style: "width: 80%; height: 200px;"
                        }).appendTo($("#" + that.fullName+slide.name));
                        $.ajax({
                            url: that.name+"/"+slide.defaultCode,
                            dataType: "text"
                        }).done(function(data){
                                $("#textboxOf" + that.fullName+slide.name).val(data);
                            });
                        $("<button>", {
                            text: "Run",
                            click: function(){
                                eval(slide.run + "($('#" + "textboxOf" + that.fullName+slide.name + "').val(), " + that.fullName + slide.drawTo + ")");
                            }
                        }).appendTo(slide.div);
                    }
                }
            });
        };
        
        this.hideSlide = function(slideName) {
        	$("#"+this.fullName+slideName).animate({
                left: "-=100%"
            }, 1000, function() {
                $("#" + this.fullName+slideName).css("display", "none");
            });
            $("#iconOf"+this.fullName+slideName).removeClass("slideIconActive");
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

            $.each(this.currentSlides.split(" "), function(key, slideName){
                that.hideSlide(slideName);
            });

            that.currentSlides = kam;
            $.each(kam.split(" "), function(key, slideName){
                that.showSlide(slideName, key, kam.indexOf(" ")>=0);
                that.currentSlide = slideName;
            });
            
            this.showArrows(kam.indexOf(" ")>=0 ? 2 : 1);
        };

        this.back = function() {
            var that = this;
            if (this.historyStack.length === 0)
            {
                alert("Toto je začátek kurzu.");
                return;
            }
            
            $.each(this.currentSlides.split(" "), function(key, slideName){
                that.hideSlide(slideName);
            });
            
            this.currentSlides = this.historyStack.pop();
            
            $.each(this.currentSlides.split(" "), function(key, val){
                that.showSlide(val);
                that.currentSlide = val;
            });
            
            this.showArrows(this.currentSlides.indexOf(" ")>=0 ? 2 : 1);
        };
  		
  		
  		// Arrows!
  		this.hideArrows = function(slidesNo) {
  			$("#" + this.fullName + "backArrow").fadeOut(200);
            $("#" + this.fullName + "forwardArrow").fadeOut(200);
  		};
  		
  		this.showArrows = function(slidesNo) {
  			if (slidesNo === 2)
            {
                $("#" + this.fullName + "backArrow").css("margin-left", "-490px");
                $("#" + this.fullName + "forwardArrow").css("margin-left", "430px");
            }
            else if (slidesNo === 1)
            {
                $("#" + this.fullName + "backArrow").css("margin-left", "-260px");
                $("#" + this.fullName + "forwardArrow").css("margin-left", "220px");
            }
            $("#" + this.fullName + "backArrow").fadeIn(200);
            $("#" + this.fullName + "forwardArrow").fadeIn(200);
  		}
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
                $.each(newLecture.data["slides"], function(i, slide){
                    var slideIcon = $("<div>", {
                        id: "iconOf" + newLecture.fullName + slide.name,
                        class: "slideIcon",
                        style: slide.icon ?
                            "background-image: url('" + name + "/" + slide.icon + "')" :
                            "background-image: url('icons/" + slide.type + ".png')"
                    }).appendTo(slideList);
                    var slideDiv = $("<div>", {
                        id: newLecture.fullName+slide.name,
                        class: "slide",
                        style: "display: none"
                    });
                    slide["div"] = slideDiv;
                    slide["iconDiv"] = slideIcon;
                    slideDiv.appendTo(innerSlides);
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