class Puppet::Parser::Relationship
  attr_accessor :source, :target, :type

  PARAM_MAP = {:relationship => :before, :subscription => :notify}

  def arrayify(resources)
    case resources
    when Puppet::Pops::Evaluator::Collectors::AbstractCollector
      resources.collected.values
    when Array
      resources
    else
      [resources]
    end
  end

  def evaluate(catalog)
    arrayify(source).each do |s|
      arrayify(target).each do |t|
        mk_relationship(s, t, catalog)
      end
    end
  end

  def initialize(source, target, type)
    @source, @target, @type = source, target, type
  end

  def param_name
    PARAM_MAP[type] || raise(ArgumentError, _("Invalid relationship type %{relationship_type}") % { relationship_type: type })
  end

  def mk_relationship(source, target, catalog)
    # There was once an assumption that this could be an array. These raise
    # assertions are here as a sanity check for 4.0 and can be removed after
    # a release or two
    #TRANSLATORS "source" is a keyword and should not be translated
    raise ArgumentError, _("source shouldn't be an array") if source.is_a?(Array)
    #TRANSLATORS "target" is a keyword and should not be translated
    raise ArgumentError, _("target shouldn't be an array") if target.is_a?(Array)
    source = source.to_s
    target = target.to_s

    unless source_resource = catalog.resource(source)
      raise ArgumentError, _("Could not find resource '%{source}' for relationship on '%{target}'") % { source: source, target: target }
    end
    unless catalog.resource(target)
      raise ArgumentError, _("Could not find resource '%{target}' for relationship from '%{source}'") % { target: target, source: source }
    end
    Puppet.debug {"Adding relationship from #{source} to #{target} with '#{param_name}'"}
    if source_resource[param_name].class != Array
      source_resource[param_name] = [source_resource[param_name]].compact
    end
    source_resource[param_name] << target
  end
end
