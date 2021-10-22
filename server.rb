require 'sinatra'
require 'sinatra/reloader' if development?
require 'pg'
require 'json'

before do 
    content_type :json
end

get '/' do 
    content_type 'text/html'
    todos = todo_items
    erb :index, :locals => {todos: todos}
end

# ----------------------------------------------------------------------------------------------------
# APIs

get '/api/todo/:id' do 
    conn = connect_db 
    id = params['id']
    conn.prepare('stmt', "SELECT * FROM todos WHERE id = $1")
    result = conn.exec_prepared('stmt', [id])

    if result.first
        result.first.to_json
    else
        { found: false, message: 'Todo not found.' }.to_json
    end
end

get '/api/todos' do 
    conn = connect_db
    results = conn.exec("SELECT * FROM todos")
    # rows = []
    rows = results.map do |row|
        row['isdone'] = row['isdone'] == 't' ? true : false
        row
    end
    rows.to_json
end

post '/api/todos' do 
    conn = connect_db
    conn.prepare('stmt', "INSERT INTO todos(title, isdone) VALUES($1, $2) RETURNING *")
    data = JSON.parse(request.body.read)
    result = conn.exec_prepared('stmt', [data["todo"], false])
    if result 
        { status: 'ok', todo: result.first }.to_json
    end
end


# ----------------------------------------------------------------------------------------------------
# Functions

def todo_items
    conn = connect_db
    results = conn.exec("SELECT * FROM todos")

    todos = results.map do |row|
        row['isdone'] = row['isdone'] == 't' ? true : false
        row
    end
    close_db(conn)
    todos
end

def connect_db
    begin
        conn = PG.connect(:dbname => 'sinatra_todo', :user => 'jeffreydelara')
        conn
    rescue PG::Error => e
        puts e.message
    end
end

def close_db(conn)
    conn.close if conn
end
