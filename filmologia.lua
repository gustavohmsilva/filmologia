local gui = require('yue.gui')
local luasql = require 'luasql.sqlite3'

local db = {}
        db.connect = function(database)
                local env = luasql.sqlite3()
                local conn = env:connect(database)
                return conn
        end
        db.create_table = function(conn)
                local command = "CREATE TABLE catalogo(\
                id INTEGER PRIMARY KEY,\
                Filme TEXT NOT NULL,\
                Produtora TEXT NOT NULL,\
                Ano INT NOT NULL)"
                conn:execute(command)
        end    
        db.create = function(conn, filme, produtora, ano)
                local query = string.format("INSERT INTO catalogo (filme, produtora, ano) VALUES ('%s','%s','%s')", filme, produtora, ano)
                conn:execute(query)

        end
        db.read_all = function(conn)
                local query = "SELECT * FROM catalogo"
                local cursor = assert(conn:execute(query))
                local result = {}
                repeat
                        line = cursor:fetch({}, 'a')
                        table.insert(result, line)
                until not line
                cursor:close()
                return result
        end
        db.last_id = function(conn)
                local query = "SELECT id FROM catalogo ORDER BY id DESC LIMIT 1"
                local cursor = assert(conn:execute(query))
                local result = {}
                local line = cursor:fetch({}, 'a')
                cursor:close()
                return line
        end
        db.delete = function(conn, rowid)
                local query = string.format('DELETE FROM catalogo WHERE "id" = %s', rowid)
                assert(conn:execute(query))
                return 
        end

local conexao = db.connect('filmologia.db')

local janela = gui.Window.create{}
janela.onclose = gui.MessageLoop.quit
janela:settitle('Catálogo Filmográfico')
janela:setcontentsize{width = 640, height = 480}

local container = gui.Container.create()
container:setstyle{padding = 10}

local dados_db = db.read_all(conexao)
tabela = gui.SimpleTableModel.create(4)
for _,v in ipairs(dados_db) do
tabela:addrow{
                tostring(v.id),
                v.Filme,
                v.Produtora,
                tostring(v.Ano)
        }
end

local container_tabela = gui.Table.create()
local colunas = {
        {name = 'Código', width = 80},
        {name = 'Filme', width = 240},
        {name = 'Produtora', width = 200},
        {name = 'Ano', width = 90}
}
for _,v in ipairs(colunas) do
        container_tabela:addcolumnwithoptions(v.name, {width = v.width})
end
container_tabela:setstyle{flex=1}
container_tabela:setmodel(tabela)

local barra_menu = gui.Container.create()
barra_menu:setstyle{padding = 0, flexdirection = 'row'}


local btn_deletar = gui.Button.create('Deletar')
btn_deletar:setenabled(true)
btn_deletar:setstyle{width = 100}

local btn_criar = gui.Button.create('Criar')
btn_criar:setenabled(true)
btn_criar:setstyle{width = 100}

function event_criar()
        local janela = gui.Window.create{}
        janela:settitle('Inserir Obra')
        janela:setcontentsize{width = 600, height = 110}

        local container = gui.Container.create()
        container:setstyle{padding = 10}

        local container_l1 = gui.Container.create()
        container_l1:setstyle{height = 30, flexdirection = 'row'}

        local container_l2 = gui.Container.create()
        container_l2:setstyle{height = 30, flexdirection = 'row'}

        local container_l3 = gui.Container.create()
        container_l3:setstyle{height = 30, flexdirection = 'row'}

        local label_filme = gui.Label.create('Filme: ')
        label_filme:setstyle{width = 80}
        label_filme:setalign('start')
        
        local entry_filme = gui.Entry.create()
        entry_filme:setstyle{flex=1}

        local label_produtora = gui.Label.create('Produtora: ')
        label_produtora:setstyle{width = 80}
        label_produtora:setalign('start')
        
        local entry_produtora = gui.Entry.create()
        entry_produtora:setstyle{flex=1}
        
        local label_ano = gui.Label.create('Filme: ')
        label_ano:setstyle{width = 80}
        
        local entry_ano = gui.Entry.create()
        entry_ano:setstyle{flex=1}

        local btn_cadastrar = gui.Button.create('Cadastrar')
        btn_cadastrar:setenabled(true)
        btn_cadastrar:setstyle{width = 100}

        function btn_cadastrar.onclick() 
                db.create(
                        conexao, 
                        entry_filme:gettext(), 
                        entry_produtora:gettext(), 
                        entry_ano:gettext()
                )
                local temp = db.last_id(conexao)
                tabela:addrow{
                        tostring(temp.id),
                        entry_filme:gettext(), 
                        entry_produtora:gettext(), 
                        entry_ano:gettext()
                }
                janela:close()
        end

        janela:setcontentview(container)
        container:addchildview(container_l1)
        container:addchildview(container_l2)
        container:addchildview(container_l3)
        container_l1:addchildview(label_filme)
        container_l1:addchildview(entry_filme)
        container_l2:addchildview(label_produtora)
        container_l2:addchildview(entry_produtora)
        container_l2:addchildview(label_ano)
        container_l2:addchildview(entry_ano)
        container_l3:addchildview(btn_cadastrar)
        janela:center()
        janela:activate()
end

function event_deletar()
        rownumber = container_tabela:getselectedrow()
        db.delete(conexao, tabela:getvalue(1, rownumber))
        tabela:removerowat(rownumber)
end

btn_criar.onclick = event_criar
btn_deletar.onclick = event_deletar

janela:setcontentview(container)
container:addchildview(container_tabela)
container:addchildview(barra_menu)
barra_menu:addchildview(btn_criar)
barra_menu:addchildview(btn_deletar)
janela:center()
janela:activate()

gui.MessageLoop.run()
conexao:close()