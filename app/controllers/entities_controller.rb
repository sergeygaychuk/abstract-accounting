class EntitiesController < ApplicationController
  
  def index
    @entities = Entity.all
  end

  def new
    @entity = Entity.new
  end

  def edit
  end

  def create
  end

  def update
  end

end
