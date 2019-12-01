class BasesController < ApplicationController

  def index
    @bases = Base.all
  end

  def create
    @base = Base.new(baseNo: params[:baseNo], baseName: params[:baseName], attendanceKind: params[:attendanceKind])
    if @base.save
      flash[:success] = "拠点登録完了しました。"
      redirect_to bases_url
    else
      render 'index'
    end
  end

  def edit
    @base = Base.find(params[:id])
  end

  def update
    @updateBase = Base.find(params[:id])
    @updateBase.baseName = params[:baseName]
    @updateBase.attendanceKind = params[:attendanceKind]
    if @updateBase.save
      flash[:success] = '拠点修正完了しました。'
      redirect_to bases_url
    else
      render 'edit'
    end
  end

  def destroy
    Base.find(params[:id]).destroy
    flash[:success] = '拠点削除完了しました。'
    redirect_to bases_url
  end

end