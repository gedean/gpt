Gem::Specification.new do |s|
  s.name          = 'gpt'
  s.version       = '0.1.0'
  s.date          = '2025-08-14'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'Cliente Ruby para GPT-5 (Responses API)'
  s.description   = 'Cliente Ruby simples para a Responses API com suporte aos recursos do GPT-5 (reasoning, verbosity, tools).'
  s.authors       = ['Gedean Dias']
  s.email         = 'gedean.dias@gmail.com'
  s.files         = Dir['README.md', 'LICENSE', 'CHANGELOG.md', 'lib/**/*']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3'
  s.homepage      = 'https://github.com/gedean/openaiext'
  s.license       = 'MIT'
  
  # Runtime dependencies
  s.add_dependency 'oj', '~> 3'
  
  # Development dependencies
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'webmock', '~> 3'
  s.add_development_dependency 'rubocop', '~> 1'
  s.add_development_dependency 'simplecov', '~> 0.22'
  s.add_development_dependency 'yard', '~> 0.9'
end