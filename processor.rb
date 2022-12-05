require 'parser/current'

class Processor < AST::Processor
    attr_reader :class_list
    attr_reader :send_list
    def initialize
      reset_class

      @class_list = Hash.new { |h,k| h[k] = [] }
      @send_list = Hash.new { |h,k| h[k] = [] }
    end

    def reset_class
      @current_class = "main"
    end

    def add_method(method_name, line_num)
      @class_list[@current_class] << { name: method_name.to_s, line: line_num }
    end

    def add_sender(import_name, line_num)
      @send_list['imports'] << { name: import_name.to_s, line: line_num }
    end

    def on_class(node)
      class_name = node.children[0].children[1].to_s

      if @current_class == "main"
        @current_class = class_name
      else
        @current_class << "::" + class_name
      end

      node.children.each { |c| process(c) }

      if @current_class.include?("::")
        @current_class.sub!("::" + class_name, "")
      else
        reset_class
      end
    end

    def on_module(node)
      module_name = node.children[0].children[1].to_s

      if @current_class == "main"
        @current_class = module_name
      else
        @current_class.prepend(module_name + "::")
      end

      node.children.each { |c| process(c) }

      @current_class.sub!(module_name, "")
    end

    # Instance methods
    def on_def(node)
      line_num    = node.loc.line
      method_name = node.children[0]

      add_method(method_name, line_num)
    end

    def on_send(node)
      line_num = node.loc.line
      import_name = node.children[0]

      add_sender(import_name, line_num)
    end

    # Class methods
    def on_defs(node)
      line_num    = node.loc.line
      method_name = "self.#{node.children[1]}"

      add_method(method_name, line_num)
    end

    def on_begin(node)
      node.children.each { |c| process(c) }
    end

    def on_each(node)
      puts(node.loc.line)
    end
end

#code = File.read('D:\Faculdade 2020.4\TCC\Git Project\TCC_Taiti\TestInterfaceEvaluation\spg_repos\hackful\app\controllers\api\v1\sessions_controller.rb')
#parsed_code = Parser::CurrentRuby.parse(code)
#parsed_code.children.each do |node|
# puts(node.loc.line)
#  puts(node.to_sexp)
#end

'''
ast = Processor.new
ast.process(parsed_code)
if !ast.class_list.empty?
  ast.class_list.each do |chave, par|
    puts(chave)
    puts(par[0][:name])
  end
end
'''