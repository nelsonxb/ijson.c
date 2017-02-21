local microtest = require('microtest')

c('parser', function()
    microtest.require('parse-tfn')
    microtest.require('parse-whitespace')
end)
