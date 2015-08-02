pandoc(rst) = readall(pipe(`echo $rst`, `pandoc --columns=80 -f rst -t markdown_github`))

function rmquote(md)
  ls = split(md, "\n")
  ls = map(ls) do l
    l == ">" ? "" :
    startswith(l, "> ") ? l[3:end] : l
  end
  join(ls, "\n")
end

escape(md) = replace(md, "\$", "\\\$")

isvalid(rst) = !ismatch(r":(func|obj|ref|class|const|math):|doctest", rst)

function convert(doc)
  if isvalid(doc)
    pandoc(doc) |> rmquote |> escape
  else
    """
    ```rst
    $(chomp(doc))
    ```
    """
  end |> chomp
end

function translate(file)
  ls = split(open(readall, file), "\n")
  doccing = false
  iscode = false
  open(file, "w") do io
    doc = IOBuffer()
    for l in ls
      if iscode
        l != "" && println(doc)
        iscode = false
      end
      doccing && l == "::" && (iscode = true)
      if l == "```rst"
        doccing = true
      elseif doccing && l == "```"
        doccing = false
        rst = takebuf_string(doc)
        println(io, convert(rst))
      elseif doccing
        println(doc, l)
      else
        println(io, l)
      end
    end
  end
end

translate("base/docs/helpdb.jl")
