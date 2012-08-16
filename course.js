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

        this.showSlide = function(slideName, order, isThereSecond, toRight) {
            if (!slideName)
            {
                this.currentSlide = this.currentSlides = slideName = data.slides[0].name;
            }

            var slide = this.getSlide(slideName);
            slide["toShow"] = true;
            
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
            if (toRight)
            {
            	slide.div.css("left", "150%");
            	slide.div.animate({
            		left: "-=100%"
            		}, 1000);
           	}
           	else
           	{
           		slide.div.css("left", "-50%");
            	slide.div.animate({
            		left: "+=100%"
            		}, 1000);
           	}
            slide.div.html("");

            if (slide.type === "html")
            {
                $.ajax({
                    url: this.name+"/"+slide.source,
                    dataType: "text"
                }).done(function(data){
                        slide.div.html(data);
                    });
            }
            else if (slide.type === "code")
            {
                $("<textarea>", {
                    id: "textboxOf" + this.fullName+slide.name,
                    style: "width: 80%; height: 200px;"
                }).appendTo(slide.div);
                $.ajax({
                    url: this.name+"/"+slide.defaultCode,
                    dataType: "text"
                }).done(function(data){
                        $("#textboxOf" + this.fullName+slide.name).val(data);
                    });
                $("<button>", {
                    text: "Run",
                    click: function(){
                        eval(slide.run + "($('#" + "textboxOf" + this.fullName+slide.name + "').val(), " + this.fullName + slide.drawTo + ")");
                    }
                }).appendTo(slide.div);
            }
        };
        
        this.hideSlide = function(slideName, toLeft) {
        	var slide = this.getSlide(slideName);
        	if (toLeft)
        	{
	        	slide.div.animate({
	                left: "-=100%"
	            }, 1000, function() {
	            	if (!slide.toShow)
	            	{
	                	slide.div.css("display", "none");
	              	}
	              	else
	              	{
	              		slide.toShow = false;
	              	};
	            });
            }
            else
            {
            	slide.div.animate({
	                left: "+=100%"
	            }, 1000, function() {
	                if (!slide.toShow)
	            	{
	                	slide.div.css("display", "none");
	              	}
	              	else
	              	{
	              		slide.toShow = false;
	              	};
	            });
            }
            slide.iconDiv.removeClass("slideIconActive");
        };

        this.historyStack = new Array();

        this.forward = function() {
            var kam, that = this, ret = true;
            
            var slide = this.getSlide(that.currentSlide);
            if (!slide.next)
            {
                alert("Toto je konec kurzu.");
                return;
            }
            
            this.historyStack.push(this.currentSlides);

            $.each(this.currentSlides.split(" "), function(key, slideName){
                that.hideSlide(slideName, true);
            });

            that.currentSlides = slide.next;
            $.each(slide.next.split(" "), function(key, slideName){
                that.showSlide(slideName, key, slide.next.indexOf(" ")>=0, true);
                that.currentSlide = slideName;
            });
            
            this.showArrows(slide.next.indexOf(" ")>=0 ? 2 : 1);
        };

        this.back = function() {
            var that = this;
            if (this.historyStack.length === 0)
            {
                alert("Toto je začátek kurzu.");
                return;
            }
            
            $.each(this.currentSlides.split(" "), function(key, slideName){
                that.hideSlide(slideName, false);
            });
            
            this.currentSlides = this.historyStack.pop();
            
            $.each(this.currentSlides.split(" "), function(key, val){
                that.showSlide(val, false);
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
  		};
  		
  		this.getSlide = function(slideName) {
  			for (var i=0; i<this.data.slides.length; i++)
  			{
  			    if (this.data.slides[i].name === slideName)
                {
                	return this.data.slides[i];
                };
            };
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
                newLecture.showSlide(undefined, 0, false, true);
            }).error(function() {
                    slideList.html("<p style='position: relative; top: 0.5em'>Course at '" + name + "' is not available.");
                    slideList.appendTo(theDiv);
                });
        }
    }
}