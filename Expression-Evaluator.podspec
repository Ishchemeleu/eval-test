Pod::Spec.new do |s|
  s.name             = 'ExpressionEvaluator'
  s.version          = '0.2.25'
  s.summary          = 'A short description of Expression-Evaluator.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = ''
  s.license          = { :type => 'None', :file => 'LICENSE' }
  s.source           = { :git => '', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/**/*'

end
