unit u_GraphicButtonBars;

interface

uses System.Classes, System.SysUtils, Vcl.Controls, Vcl.Graphics;

type
  TCaptionArray = array of string;

  // lighter version of u_ButtonBars.TButtonBar
  TButtonBar = class(TGraphicControl)
  private
    fCaptions: TCaptionArray;
    fBitmap: TBitmap;
    fItemWidth: Integer;
    fItemRemainder: Integer;
    fItemIndex: Integer;
    fOnClick: TNotifyEvent;
    function ItemAt(X, Y: Integer): Integer;
    procedure SetCaptions(const Value: TCaptionArray);
    procedure Layout;
    procedure SetItemIndex(const Value: Integer);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Captions: TCaptionArray read fCaptions write SetCaptions;
    property ItemIndex: Integer read fItemIndex write SetItemIndex;
    property OnClick: TNotifyEvent read fOnClick write fOnClick;
  end;

implementation

uses System.Types, System.Math, Vcl.GraphUtil, Vcl.Themes;

{ TButtonBar }

constructor TButtonBar.Create(AOwner: TComponent);
begin
  inherited;
  fBitmap := TBitmap.Create;
  fItemIndex := -1;
end;

destructor TButtonBar.Destroy;
begin
  fBitmap.Free;
  inherited;
end;

procedure TButtonBar.Layout;
begin
  var count := Length(fCaptions);
  if count = 0 then
  begin
    fItemWidth := 0;
    fItemRemainder := 0;
    Invalidate;
    Exit;
  end;

  fItemWidth := (Self.ClientWidth - 2) div count;
  fItemRemainder := (Self.ClientWidth - 2) mod count;
  Invalidate;
end;

procedure TButtonBar.Paint;
begin
  if Length(fCaptions) = 0 then
  begin
    Canvas.Brush.Color := StyleServices.GetStyleColor(scGenericBackground);
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Style := psClear;
    Canvas.Rectangle(Self.ClientRect);
    Exit;
  end;

  // bitmap needs to be the right size
  if (fBitmap.Width <> Self.ClientWidth) or (fBitmap.Height <> Self.ClientHeight) then
  begin
    fBitmap.SetSize(Self.ClientWidth, Self.ClientHeight);
  end;

  fBitmap.Canvas.Font := Self.Font;

  // draw background
  var r := Self.ClientRect;
  fBitmap.Canvas.Brush.Style := bsSolid;
  fBitmap.Canvas.Brush.Color := StyleServices.GetSystemColor(clBtnFace);
  fBitmap.Canvas.Pen.Style := psSolid;
  fBitmap.Canvas.Pen.Color := StyleServices.GetSystemColor(clBtnShadow);
  fBitmap.Canvas.Rectangle(r);

  Inc(r.Left);
  Dec(r.Right);
  Inc(r.Top);
  Dec(r.Bottom);
  r.Right := r.Left + fItemWidth;
  for var i := 0 to Length(fCaptions) - 1 do
  begin
    var captionText := fCaptions[i];
    var captionRect := r;
    if i = Length(fCaptions) - 1 then
    begin
      r.Right := r.Right + fItemRemainder;
      captionRect := r;
      captionRect.Right := Self.ClientWidth - 1;
    end;
    captionRect.Inflate(-1, -1);

    if i = fItemIndex then
    begin
      fBitmap.Canvas.Brush.Style := bsSolid;
      fBitmap.Canvas.Brush.Color := StyleServices.GetSystemColor(clHighlight);
      fBitmap.Canvas.Pen.Style := psClear;
      fBitmap.Canvas.Rectangle(r);
      fBitmap.Canvas.Brush.Color := GetShadowColor(StyleServices.GetSystemColor(clHighlight), -50);
      fBitmap.Canvas.FrameRect(r);

      fBitmap.Canvas.Pen.Style := psSolid;
      fBitmap.Canvas.Pen.Width := 1;
      fBitmap.Canvas.Pen.Color := GetHighlightColor(StyleServices.GetSystemColor(clHighlight), 15);
      fBitmap.Canvas.Polyline([Point(r.Left + 1, r.Bottom - 1), Point(r.Right - 1, r.Bottom - 1), Point(r.Right - 1, R.Top)]);

      fBitmap.Canvas.Font.Color := StyleServices.GetSystemColor(clHighlightText);
      fBitmap.Canvas.Brush.Style := bsClear;
      fBitmap.Canvas.TextRect(captionRect, captionText, [tfSingleLine, tfVerticalCenter, tfCenter]);
    end
    else
    begin
      if i < Length(fCaptions) -1 then
      begin
        fBitmap.Canvas.Pen.Style := psSolid;
        fBitmap.Canvas.Pen.Width := 1;
        fBitmap.Canvas.Pen.Color := StyleServices.GetStyleColor(scBorder);
        fBitmap.Canvas.MoveTo(r.Right, r.Top);
        fBitmap.Canvas.LineTo(r.Right, r.Bottom);
      end;

      fBitmap.Canvas.Brush.Style := bsClear;
      fBitmap.Canvas.Font.Color := StyleServices.GetStyleFontColor(sfButtonTextNormal);
      fBitmap.Canvas.TextRect(captionRect, captionText, [tfSingleLine, tfVerticalCenter, tfCenter]);
    end;

    r.Offset(fItemWidth, 0);

  end;

  Canvas.CopyRect(Canvas.ClipRect, fBitmap.Canvas, Canvas.ClipRect);
end;

function TButtonBar.ItemAt(X, Y: Integer): Integer;
begin
  var innerRect := Self.ClientRect;
  Inc(innerRect.Left);
  Dec(innerRect.Right);
  Inc(innerRect.Top);
  Dec(innerRect.Bottom);

  if not innerRect.Contains(Point(X, Y)) then
    Exit(-1);

  var count := Length(fCaptions);
  if (fItemWidth <= 0) or (count = 0) then
    Exit(-1);
  if X >= innerRect.Left + (fItemWidth * (count - 1)) then
    Exit(count - 1);
  Result := (X - innerRect.Left) div fItemWidth;
end;

procedure TButtonBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button <> mbLeft then
    Exit;

  ItemIndex := ItemAt(X, Y);
  if (fItemIndex >= 0) and Assigned(fOnClick) then
    fOnClick(Self);
end;

procedure TButtonBar.Resize;
begin
  inherited;
  Layout;
end;

procedure TButtonBar.SetCaptions(const Value: TCaptionArray);
begin
  fCaptions := Value;
  Layout;
end;

procedure TButtonBar.SetItemIndex(const Value: Integer);
begin
  fItemIndex := Value;
  Invalidate;
end;

end.
