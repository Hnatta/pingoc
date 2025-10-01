module("luci.controller.yamloc", package.seeall)
function index()
entry({"admin","services","yamloc"}, template("yamloc"), _("Yaml OC"), 96).leaf=true

end
