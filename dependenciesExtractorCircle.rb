require 'json'
require 'csv'
require 'git'
require 'fileutils'
require 'logger'

$log = Logger.new('logs.log')
class DependenciesExtractor

  def preprocess(target_project)
    output_path = Dir.pwd + '/TestInterfaceEvaluation/output.html' 
    Dir.chdir(target_project){
      `rubrowser > "#{output_path}"`
    }
  end

  def process()
    output_path = Dir.pwd + '/TestInterfaceEvaluation/output.html'
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json'
    extract(output_path)
    if !File.zero?(dependencies_path)
      hashJ = JSON.parse(read_file(dependencies_path))
      write_file(hashJ.to_json, dependencies_path)
    end
    #hashJ = handle_missing_names(hashJ)
  end

  def extract(output_path)
    file_content = read_file(output_path)
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json'
    json_regex = /var data = (.*);/
    json_data = ""
    if !json_regex.match(file_content).nil?
      json_data = json_regex.match(file_content)[1]
    end
    write_file(json_data, dependencies_path)
  end

  def find_all_relations(file_paths)
    response = ''
    response_circular = ''
    file_path_arr = file_paths.split(",")
    file_path_arr.each do |file_path|
      dependency_def = find_definition(file_path, "file")
      if dependency_def != 'Not found'
        strings = find_formated_relations(file_path)
        response += strings[0]
        response_circular += strings[1]
      end
    end
    return [(response[0..-2]).split(',').uniq.join(","), (response_circular[0..-2]).split(',').join(",")]
  end

  def new_find_all_relations(file_paths)
    response = ''
    file_path_arr = file_paths.split(",")
    $log.debug{file_path_arr}
    file_path_arr.each do |file_path|
      dependency_def = find_definition(file_path, "file")
      if dependency_def != 'Not found'
        $log.debug{dependency_def}
        #response += find_formated_relations(file_path)
      end
    end
    #return (response[0..-2]).split(',').uniq.join(",")
  end

  def find_formated_relations(file_path)
    relations = find_relations(file_path)
    response_circular = ''
    response = ''
    if relations != 'Not found'
      if !file_path.nil?
        relations_arr = relations[file_path.gsub(/\\/.to_s, '/'.to_s)].uniq { |t| t['namespace'] }
      end
      relations_arr.each do |relation|
        path = find_definition(relation['namespace'], "namespace")
        if path != 'Not found'
          actual_path = Dir.pwd + 'TestInterfaceEvaluation/spg_repos/'
          k = actual_path.length + 1
          while(path[relation['namespace'].downcase][0]['file'][k] != '/')
            k += 1
          end 
          response += path[relation['namespace'].downcase][0]['file'][k+1..-1] + ','
          if(path[relation['namespace'].downcase][0]['circular'])
            response_circular += 'true' + ','
          else
            response_circular += 'false' + ','
          end
        end
      end
    end
    #Return comes with extra ',' take care
    return [response, response_circular]
  end

  def find_relations(file_path)
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json'
    json = JSON.parse(read_file(dependencies_path))
    dep = Hash.new
    json["relations"].each do |dependency|
      if !dependency["file"].nil? && !file_path.nil?
        if dependency["file"].gsub(/\\|\//.to_s, ''.to_s).downcase == file_path.gsub(/\\|\//.to_s, ''.to_s).downcase
          dep["#{dependency["file"]}"] ? dep["#{dependency["file"]}"].push(dependency) : dep["#{dependency["file"]}"] = [dependency]
        end
      end
    end
    dep.empty? ? 'Not found' : dep
  end

  def find_definition(search_param, attribute)
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json'
    json = JSON.parse(read_file(dependencies_path))
    dep = Hash.new
    json["definitions"].each do |definition|
      if !definition[attribute].nil? && !search_param.nil?
        if definition[attribute].gsub(/\\|\//.to_s, ''.to_s).to_s.downcase == search_param.gsub(/\\|\//.to_s, ''.to_s).to_s.downcase
          dep["#{definition[attribute]}"] ? dep["#{definition[attribute]}"].push(definition) : dep["#{definition[attribute]}".downcase] = [definition]
        end
      end
    end
    dep.empty? ? 'Not found' : dep
  end
# TODO: Catch more names correctly 
  def find_missing_name(path, target_line)
    name_regex0 = /^([A-Z][^.]+)/
    name_regex1 = / +:*([A-Z][^(.|,| )]+)/
    name_regex2 = /\(([A-Z].*?)(\)|\.|\,)/
    name_regex3 = /(\{:*([A-Z].*?[^.]+?)\})/
    colon_regex = /::/
    lines = File.readlines(path)
    target_line_value = lines[target_line - 1]
    if(name_regex0.match?(target_line_value))
      prob_name = name_regex0.match(target_line_value)[1]
    elsif(name_regex2.match?(target_line_value))
      prob_name = name_regex2.match(target_line_value)[1]
    elsif(name_regex3.match?(target_line_value))
      prob_name = name_regex3.match(target_line_value)[2]
      prob_name = name_regex0.match?(prob_name) ? name_regex0.match(prob_name)[1] : prob_name 
    elsif(name_regex1.match?(target_line_value))
      prob_name = name_regex1.match(target_line_value)[1]
    end

    if(!prob_name.nil?)
      prob_name = prob_name[-1] == '.' ? prob_name.chop : prob_name
    end

    while(colon_regex.match?(prob_name))
      prob_name = /::.*?([^.]+)/.match(prob_name)[1]
    end
    find_definition(prob_name, "namespace") != 'Not found' ? find_definition(prob_name, "namespace") : ''
  end

  def handle_missing_names(json)
    bugged = 0
    total = 0
    json["relations"].each_with_index do |dependency, idx|
      total += 1
      if dependency["caller"].empty? && !dependency["file"].empty? && dependency["line"]
        json["relations"][idx]["caller"] = find_missing_name(json["relations"][idx]["file"], json["relations"][idx]["line"])
        bugged += 1
      end
    end
    json
  end

  def read_file(path)
    File.open(path, 'rb') { |file| file.read }
  end

  def write_file(text, path)
    File.open(path, 'w') do |f|
      f.write text
    end
  end

  def get_all_dependencies(project_path, file_paths)
    preprocess(project_path)
    process()
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json'
    if !File.zero?(dependencies_path)
      $log.debug{'Dependencies path nao esta vazio!'}
      return find_all_relations(file_paths)
    else
      return ""
    end
  end

  def new_get_all_dependencies(project_path, file_paths)
    preprocess(project_path)
    process()
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json'
    if !File.zero?(dependencies_path)
      $log.debug{'Dependencies path nao esta vazio!'}
      return new_find_all_relations(file_paths)
    else
      return ""
    end
  end
end

def add_home_path(home_path, testi)
  correct_string = testi[1..-2]
  testi_new = correct_string.split(',')
  final_string = ''
  string_aux = ''
  testi_new.length.times do |k|
    i = 0
    while(testi_new[k][i] == ' ')
      i += 1
    end
    j = testi_new[k].length - 1
    while(testi_new[k][j] == ' ')
      j -= 1
    end
    fix_path = testi_new[k][i..j]
    string_aux = home_path + fix_path
    if(k != testi_new.length - 1)
      final_string = final_string + string_aux + ','
    else
      final_string = final_string + string_aux
    end
  end
  return final_string
end

def clean_string(testi)
  correct_string = testi[1..-2]
  testi_new = correct_string.split(',')
  final_string = ''
  string_aux = ''
  testi_new.length.times do |k|
    i = 0
    while(testi_new[k][i] == ' ')
      i += 1
    end
    j = testi_new[k].length - 1
    while(testi_new[k][j] == ' ')
      j -= 1
    end
    fix_path = testi_new[k][i..j]
    string_aux = fix_path
    if(k != testi_new.length - 1)
      final_string = final_string + string_aux + ','
    else
      final_string = final_string + string_aux
    end
  end
  return final_string
end

def calc_metrics(taski, testi)
  list_testi = testi.split(',')
  list_taski = taski.split(',')
  intersessao = 0
  list_testi.length.times do |k|
    if(list_taski.include?(list_testi[k]))
      intersessao += 1
    end
  end
  precision = intersessao.to_f / list_testi.length
  recall = intersessao.to_f / list_taski.length
  f2 = 0
  if (precision + recall) != 0
    f2 = (5 * precision * recall).to_f / ((4 * precision) + recall)
  end
  return [precision.round(2), recall.round(2), f2.round(2)]
end

def main(taiti_result, task_csv)
  table_taiti = CSV.parse(File.read(taiti_result), headers: true)
  table_task = CSV.parse(File.read(task_csv), headers: true)
  #TODO Checar se arquivo existe, caso exista limpar ele antes de escrever para não pegar lixo junto
  CSV.open("testidepcircle.csv", "wb") do |csv|
    csv << (table_taiti.headers + [ 'TestIDep', 'Circular'])
    table_taiti.each.with_index do |row, i|
      name = table_task[i]['REPO_URL'].split('/')[-1][0..-5]
      $log.debug{'Executing Code to Get All Dependencies of Repo:' + name}
      dir = 'TestInterfaceEvaluation/spg_repos/' + name
      if(Dir.exists?(dir))
        git = Git.open(dir)
      else
        git = Git.clone(table_task[i]['REPO_URL'], name, path: 'TestInterfaceEvaluation/spg_repos')
        #Needed for git windows, some cases may cause bug for checkout
        git.config('core.protectNTFS', 'false')
      end
      #puts(git.show())
      git.checkout(table_task[i]['LAST'])
      #puts(git.show())
      current_path = Dir.pwd + '/'+dir + '/'
      testi = add_home_path(current_path, table_taiti[i]['TestI'])
      testi_string = table_taiti[i]['TestI'][1..-2]
      all_dependencies = DependenciesExtractor.new.get_all_dependencies(current_path, testi)
      if all_dependencies != ""
        dependencies_testi = all_dependencies[0]
        resultado = '[' + dependencies_testi + ']'
        circular_testi = all_dependencies[1]
        resultado_circular = '[' + circular_testi + ']'
        csv << (row.fields + [resultado, resultado_circular])
      else
        csv << (row.fields + ['[FAIL]', '[FAIL]'])
      end
    end
  end
end

def new_main(taiti_result, task_csv)
  table_taiti = CSV.parse(File.read(taiti_result), headers: true)
  table_task = CSV.parse(File.read(task_csv), headers: true)
  table_taiti.each.with_index do |row, i|
    name = table_task[i]['REPO_URL'].split('/')[-1][0..-5]
    $log.debug{'Executing Code to Get All Dependencies of Repo:' + name}
    dir = 'TestInterfaceEvaluation/spg_repos/' + name
    if(Dir.exists?(dir))
      git = Git.open(dir)
    else
      git = Git.clone(table_task[i]['REPO_URL'], name, path: 'TestInterfaceEvaluation/spg_repos')
      #Needed for git windows, some cases may cause bug for checkout
      git.config('core.protectNTFS', 'false')
    end
    #puts(git.show())
    git.checkout(table_task[i]['LAST'])
    #puts(git.show())
    current_path = Dir.pwd + '/'+dir + '/'
    testi = add_home_path(current_path, table_taiti[i]['TestI'])
    testi_string = table_taiti[i]['TestI'][1..-2]
    all_dependencies = DependenciesExtractor.new.new_get_all_dependencies(current_path, testi)
  end
end
main(ARGV[0], ARGV[1])
#new_main('taiti_result.csv','tasks_taiti.csv')