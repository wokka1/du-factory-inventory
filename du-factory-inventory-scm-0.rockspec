package = "du-factory-inventory"
version = "scm-0"
source = {
   url = "git+https://github.com/1337joe/du-factory-inventory",
   branch = "main",
}
description = {
   summary = "Dual Universe screen-based factory inventory monitor.",
   detailed = "Configurable, screen-based factory inventory monitor for Dual Universe.",
   homepage = "https://du.w3asel.com/du-factory-inventory/",
   license = "MIT",
}
dependencies = {
   "lua >= 5.2",
   "dkjson",

   -- build/test dependencies
   "luaunit",
   "luacov",
   "du-mocks",
   "du-bundler",
}
build = {
   type = "builtin",
   modules = {},
   copy_directories = {},
}
