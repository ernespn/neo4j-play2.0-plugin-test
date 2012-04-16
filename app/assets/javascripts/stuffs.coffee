class Stuffs extends Spine.Module

  init: (params) =>
    @controller = new Controller(params)

  destroy: () =>
    @controller.destroy()

  class Form extends Spine.Controller
    className:  'form'
    events:
      "submit form.addStuff" :     "create"

    render: (item) =>
      @html $("#stuffFormTemplate").tmpl ( item )
      @rendered = true
      @

    create: (e)=>
      e.preventDefault()
      stuff = Stuff.fromForm(e.target)
      stuff.save()
      @el.hide()
      false

  class Controller extends Spine.Controller
    className: "stuffs"

    elements:
      '.list':  "list"

    events:
      'click i.addStuff': "showForm"

    constructor: (params)->
      super

      @selectorEl = params.selectorEl

      @data =
        stuffs: []
        relations: []

      @width = 960
      @height = 500
      @color = d3.scale.category10()


      Stuff.bind "create", @newAdd
      Stuff.bind "refresh", @fetched


      @render()

      Stuff.fetch()

      @addForm = new Form()


      #try with SSE http://www.html5rocks.com/en/tutorials/eventsource/basics/
      #using https://github.com/rwldrn/jquery.eventsource
      $.eventsource({
        label: "stuff-stream",
        url: "/stream/stuff/add",
        dataType: "json",

        message: ( data ) =>
          @newAdd(new Stuff(data))
      })

      @restart()

    newAdd:(stuff) =>
       stuff.x = Math.random()*(@width-50)+25
       stuff.y = Math.random()*(@height-50)+25
       @data.stuffs.push(stuff)
       @data.relations.push({source:@data.stuffs[0], target:stuff})
       @restart()

    render: =>
      t = $('#stuffsTemplate').tmpl()
      @html(t)

      @svg = d3.select(@selectorEl).append("svg")
         .attr("width", @width)
         .attr("height", @height)

      @force = d3.layout.force()
        .charge(-120)
        .linkDistance(30)
        .size([@width, @height])
      @
    @

    rndStuff: (excl) =>
      n = @data.stuffs[Math.floor(Math.random()*@data.stuffs.length)]
      n = @rndStuff(excl) if excl and n is excl
      n

    fetched: () =>
      @data.stuffs = Stuff.all()
      nl = Math.random()*150

      @data.relations.length = 0
      if @data.stuffs.length > 2
        for n in [0..nl]
          s = @rndStuff()
          t = @rndStuff(s)
          @data.relations.push(
            source: s,
            target: t
          )

      console.dir(@data.relations)

      @restart()

    restart: () =>
      @links = @svg.selectAll("line.link")
          .data(@data.relations)
        .enter().append("svg:line")
          .attr("class", "link")

      @nodes = @svg.selectAll("circle.node")
          .data(@data.stuffs)
        .enter().append("svg:circle")
          .attr("class", "node")
          .attr("r", 5)
          .attr("fill", (d) =>
            if d.group
              @color(d.group)
            else
              "red"
          )
          .call(@force.drag)

      @force
      .nodes(@data.stuffs)
      .links(@data.relations)
      .on("tick", () =>
          @nodes
            .attr("cx", (d) -> d.x = Math.max(5, Math.min(960 - 5, d.x)))
            .attr("cy", (d) -> d.y = Math.max(5, Math.min(500 - 5, d.y)))

          @links
            .attr("x1", (d) -> d.source.x)
            .attr("y1", (d) -> d.source.y)
            .attr("x2", (d) -> d.target.x)
            .attr("y2", (d) -> d.target.y)
      )
      .start()

      @

    showForm: () =>
      if @addForm.rendered
        @addForm.el.show()
      else
        @append(@addForm.render())

    destroy:() =>
      @release()

window.Stuffs = Stuffs
