#Run methods with ruby -r "D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/dependenciesExtractor.rb" -e "DependenciesExtractor.new.find_all_relations 'D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/tracks/app/controllers/application_controller.rb,D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/tracks/lib/login_system.rb'"

require 'json'
require 'csv'
require 'git'
require 'fileutils'
class DependenciesExtractor

  def preprocess(target_project)
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json' 
    Dir.chdir(target_project){
      `rubrowser -j > "#{dependencies_path}"`
    }
  end
"""
  def process()
    extract('D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/output.html')
    hashJ = JSON.parse(read_file('D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/TestInterfaceEvaluation/dependencies.json'))
    hashJ = handle_missing_names(hashJ)
    write_file(hashJ.to_json, 'D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/TestInterfaceEvaluation/dependencies.json')
  end

  def extract(output_path)
    file_content = read_file(output_path)
    json_regex = /var data = (.*);/
    json_data = json_regex.match(file_content)[1]
    write_file(json_data, 'D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/TestInterfaceEvaluation/dependencies.json')
  end
"""
  def find_all_relations(file_paths)
    response = ''
    file_path_arr = file_paths.split(",")
    file_path_arr.each do |file_path|
      dependency_def = find_definition(file_path, "file")
      if dependency_def != 'Not found'
        response += find_formated_relations(file_path)
      end
    end
    return (response[0..-2]).split(',').uniq.join(",")
  end

  def find_formated_relations(file_path)
    relations = find_relations(file_path)
    response = ''
    if relations != 'Not found'
      relations_arr = relations[file_path.gsub(/\\/, '/')].uniq { |t| t['namespace'] }
      relations_arr.each do |relation|
        path = find_definition(relation['namespace'], "namespace")
        if path != 'Not found'
          actual_path = Dir.pwd + 'TestInterfaceEvaluation/spg_repos/'
          k = actual_path.length + 1
          while(path[relation['namespace'].downcase][0]['file'][k] != '/')
            k += 1
          end
          response += path[relation['namespace'].downcase][0]['file'][k+1..-1] + ','
        end
      end
    end
    #Return comes with extra ',' take care
    response
  end

  def find_relations(file_path)
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json'
    json = JSON.parse(read_file(dependencies_path))
    dep = Hash.new
    json["relations"].each do |dependency|
      if dependency["file"].gsub(/\\|\//, '').downcase == file_path.gsub(/\\|\//, '').downcase
        dep["#{dependency["file"]}"] ? dep["#{dependency["file"]}"].push(dependency) : dep["#{dependency["file"]}"] = [dependency]
      end
    end
    dep.empty? ? 'Not found' : dep
  end

  def find_definition(search_param, attribute)
    dependencies_path = Dir.pwd + '/TestInterfaceEvaluation/dependencies.json'
    json = JSON.parse(read_file(dependencies_path))
    dep = Hash.new
    json["definitions"].each do |definition|
      if definition[attribute].gsub(/\\|\//.to_s, '').downcase == search_param.gsub(/\\|\//.to_s, '').downcase
        dep["#{definition[attribute]}"] ? dep["#{definition[attribute]}"].push(definition) : dep["#{definition[attribute]}".downcase] = [definition]
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
    return find_all_relations(file_paths)
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
    f2 = (2 * precision * recall).to_f / (precision + recall)
  end
  return [precision.round(2), recall.round(2), f2.round(2)]
end

def main(taiti_result, task_csv)
  table_taiti = CSV.parse(File.read(taiti_result), headers: true)
  table_task = CSV.parse(File.read(task_csv), headers: true)
  #TODO Checar se arquivo existe, caso exista limpar ele antes de escrever para não pegar lixo junto
  CSV.open("testidep.csv", "wb") do |csv|
    csv << (table_taiti.headers + [ 'TestIDep', 'PrecisionI', 'RecallI', 'F2I', 'PrecisionDep', 'RecallDep','F2Dep' ])
    table_taiti.each.with_index do |row, i|
      name = table_taiti[i]['Project'].split('/')[-1]
      puts('Executing Code to Get All Dependencies of Repo:' + name)
      dir = 'TestInterfaceEvaluation/spg_repos/' + name
      if(Dir.exists?(dir))
        git = Git.open(dir)
      else
        git = Git.clone(table_taiti[i]['Project'], name, path: 'TestInterfaceEvaluation/spg_repos')
      end
      git.checkout(table_task[i]['LAST'])
      #puts(git.show())
      current_path = Dir.pwd + '/'+dir + '/'
      testi = add_home_path(current_path, table_taiti[i]['TestI'])
      testi_string = table_taiti[i]['TestI'][1..-2]
      resultado = '[' + table_taiti[i]['TestI'][1..-2] + ','+DependenciesExtractor.new.get_all_dependencies(current_path, testi) + ']'
      cleaned_testi = clean_string(table_taiti[i]['TestI'])
      cleaned_testdep = clean_string(resultado)
      cleaned_changed = clean_string(table_taiti[i]['Changed files'])
      metrics_testi = calc_metrics(cleaned_changed, cleaned_testi)
      precisioni = metrics_testi[0]
      recalli = metrics_testi[1]
      f2i = metrics_testi[2]
      metrics_testdep = calc_metrics(cleaned_changed, cleaned_testdep)
      precisiondep = metrics_testdep[0]
      recalldep = metrics_testdep[1]
      f2dep = metrics_testdep[2]
      csv << (row.fields + [ resultado, precisioni, recalli, f2i, precisiondep, recalldep, f2dep ])
    end
  end
end

#add_home_path(Dir.pwd, '[app/controllers/mentor_teacher/schedules_controller.rb, app/controllers/user_sessions_controller.rb, app/helpers/mentor_teacher/schedules_helper.rb, app/models/timeslot.rb, app/models/user_session.rb, app/views/mentor_teacher/schedules/_form.html.haml, app/views/mentor_teacher/schedules/new.html.haml, app/views/user_sessions/new.html.haml, app/views/user_sessions/shared/_error_messages.html.erb  ]')
main('taiti_result.csv', 'tasks_taiti.csv')
#DependenciesExtractor.new.get_all_dependencies('D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/TestInterfaceEvaluation/spg_repos/diaspora', 'D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/TestInterfaceEvaluation/spg_repos/diaspora/app/controllers/streams_controller.rb')
#DependenciesExtractor.new.extract("D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/output.html")
#DependenciesExtractor.new.find_formated_relations('D:\Faculdade 2020.4\TCC\TestInterfaceEvaluationWithDeps\TestInterfaceEvaluation\spg_repos\diaspora\app\models\user.rb')
#DependenciesExtractor.new.find_all_relations('D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/TestInterfaceEvaluation/spg_repos/diaspora/app/controllers/home_controller.rb')
#DependenciesExtractor.new.find_definition('D:\Faculdade 2020.4\TCC\TestInterfaceEvaluationWithDeps\TestInterfaceEvaluation\spg_repos\TheOdinProject_theodinproject\app\models\user.rb', "file")
#DependenciesExtractor.new.process()
#DependenciesExtractor.new.preprocess('D:/Faculdade 2020.4/TCC/TestInterfaceEvaluationWithDeps/TestInterfaceEvaluation/spg_repos/diaspora')