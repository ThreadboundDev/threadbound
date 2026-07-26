param(
    [string]$WeaponChromaSource = "",
    [string]$MotionChromaSourceDirectory = "",
    [string]$StationaryAttackVideo = "",
    [string]$BackpedalAttackVideo = "",
    [string]$FfmpegPath = "",
    [switch]$RegisterExistingMotion
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$outputRoot = Join-Path $projectRoot "Assets\Threadborne\Player\Normalized_V2"
$weaponReference = Join-Path $projectRoot "docs\art\concept_art\Weapon Model Bronze Long Handle.png"

$outputDirectories = @(
    "idle",
    "run",
    "jump",
    "grapple",
    "movement",
    "attacks",
    "weapon"
)

foreach ($directory in $outputDirectories) {
    New-Item -ItemType Directory -Force -Path (Join-Path $outputRoot $directory) | Out-Null
}

$normalizerSource = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class ThreadboundAnimationNormalizer
{
    private sealed class Component
    {
        public readonly List<int> Pixels = new List<int>();
        public int MinX = int.MaxValue;
        public int MinY = int.MaxValue;
        public int MaxX = int.MinValue;
        public int MaxY = int.MinValue;
        public long SumR;
        public long SumG;
        public long SumB;

        public void Add(int index, int x, int y, Color color)
        {
            Pixels.Add(index);
            MinX = Math.Min(MinX, x);
            MinY = Math.Min(MinY, y);
            MaxX = Math.Max(MaxX, x);
            MaxY = Math.Max(MaxY, y);
            SumR += color.R;
            SumG += color.G;
            SumB += color.B;
        }
    }

    public static void NormalizeGrid(
        string inputPath,
        string outputPath,
        int columns,
        int rows,
        int targetCellSize,
        float contentScale)
    {
        using (var source = new Bitmap(inputPath))
        using (var output = new Bitmap(columns * targetCellSize, rows * targetCellSize, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(output))
        {
            int sourceCellWidth = source.Width / columns;
            int sourceCellHeight = source.Height / rows;
            // Scale the authored source cell, not the destination cell. Scaling
            // from the destination size made values above 1.0 extend outside
            // their atlas region and overwrite adjacent frames.
            int drawWidth = Math.Max(1, (int)Math.Round(sourceCellWidth * contentScale));
            int drawHeight = Math.Max(1, (int)Math.Round(sourceCellHeight * contentScale));
            int insetX = (targetCellSize - drawWidth) / 2;
            int insetY = (targetCellSize - drawHeight) / 2;

            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;

            for (int row = 0; row < rows; row++)
            {
                for (int column = 0; column < columns; column++)
                {
                    var sourceRect = new Rectangle(
                        column * sourceCellWidth,
                        row * sourceCellHeight,
                        sourceCellWidth,
                        sourceCellHeight);
                    var targetRect = new Rectangle(
                        column * targetCellSize + insetX,
                        row * targetCellSize + insetY,
                        drawWidth,
                        drawHeight);
                    graphics.DrawImage(source, targetRect, sourceRect, GraphicsUnit.Pixel);
                }
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void BuildSelectedFrameGrid(
        string frameDirectory,
        string outputPath,
        int[] frameIndices,
        int columns,
        int rows,
        int cellSize)
    {
        if (frameIndices.Length > columns * rows)
        {
            throw new ArgumentException("Selected frames exceed the target grid capacity.");
        }

        using (var output = new Bitmap(
            columns * cellSize,
            rows * cellSize,
            PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(output))
        {
            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;

            for (int index = 0; index < frameIndices.Length; index++)
            {
                string framePath = Path.Combine(
                    frameDirectory,
                    String.Format("frame_{0:D3}.png", frameIndices[index]));
                if (!File.Exists(framePath))
                {
                    throw new FileNotFoundException("Missing extracted video frame.", framePath);
                }

                using (var frame = new Bitmap(framePath))
                {
                    int column = index % columns;
                    int row = index / columns;
                    var targetRect = new Rectangle(
                        column * cellSize,
                        row * cellSize,
                        cellSize,
                        cellSize);
                    graphics.DrawImage(
                        frame,
                        targetRect,
                        new Rectangle(0, 0, frame.Width, frame.Height),
                        GraphicsUnit.Pixel);
                }
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void ResizeImage(
        string inputPath,
        string outputPath,
        int targetWidth,
        int targetHeight)
    {
        using (var source = new Bitmap(inputPath))
        using (var output = new Bitmap(
            targetWidth,
            targetHeight,
            PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(output))
        {
            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;
            graphics.DrawImage(
                source,
                new Rectangle(0, 0, targetWidth, targetHeight),
                new Rectangle(0, 0, source.Width, source.Height),
                GraphicsUnit.Pixel);
            output.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void ClearPixelsOutsideReference(
        string inputPath,
        string outputPath,
        int columns,
        int rows,
        int referenceFrame,
        int targetFrame,
        int regionX,
        int regionY,
        int regionWidth,
        int regionHeight)
    {
        using (var source = new Bitmap(inputPath))
        using (var output = new Bitmap(
            source.Width,
            source.Height,
            PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(output))
            {
                graphics.Clear(Color.Transparent);
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            int cellWidth = source.Width / columns;
            int cellHeight = source.Height / rows;
            int referenceColumn = referenceFrame % columns;
            int referenceRow = referenceFrame / columns;
            int targetColumn = targetFrame % columns;
            int targetRow = targetFrame / columns;
            int right = Math.Min(cellWidth, regionX + regionWidth);
            int bottom = Math.Min(cellHeight, regionY + regionHeight);

            for (int y = Math.Max(0, regionY); y < bottom; y++)
            {
                for (int x = Math.Max(0, regionX); x < right; x++)
                {
                    Color reference = source.GetPixel(
                        referenceColumn * cellWidth + x,
                        referenceRow * cellHeight + y);
                    if (reference.A > 2)
                    {
                        continue;
                    }

                    output.SetPixel(
                        targetColumn * cellWidth + x,
                        targetRow * cellHeight + y,
                        Color.FromArgb(0, 0, 0, 0));
                }
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void CopyAnimationFrame(
        string inputPath,
        string outputPath,
        int columns,
        int rows,
        int sourceFrame,
        int targetFrame)
    {
        using (var source = new Bitmap(inputPath))
        using (var output = new Bitmap(
            source.Width,
            source.Height,
            PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(output))
            {
                graphics.Clear(Color.Transparent);
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(source, 0, 0);

                int cellWidth = source.Width / columns;
                int cellHeight = source.Height / rows;
                var sourceRect = new Rectangle(
                    (sourceFrame % columns) * cellWidth,
                    (sourceFrame / columns) * cellHeight,
                    cellWidth,
                    cellHeight);
                var targetRect = new Rectangle(
                    (targetFrame % columns) * cellWidth,
                    (targetFrame / columns) * cellHeight,
                    cellWidth,
                    cellHeight);
                graphics.DrawImage(
                    source,
                    targetRect,
                    sourceRect,
                    GraphicsUnit.Pixel);
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    private static Rectangle FindAlphaBounds(Bitmap bitmap, byte threshold)
    {
        int minX = bitmap.Width;
        int minY = bitmap.Height;
        int maxX = -1;
        int maxY = -1;

        for (int y = 0; y < bitmap.Height; y++)
        {
            for (int x = 0; x < bitmap.Width; x++)
            {
                if (bitmap.GetPixel(x, y).A < threshold)
                {
                    continue;
                }

                minX = Math.Min(minX, x);
                minY = Math.Min(minY, y);
                maxX = Math.Max(maxX, x);
                maxY = Math.Max(maxY, y);
            }
        }

        return maxX >= minX
            ? Rectangle.FromLTRB(minX, minY, maxX + 1, maxY + 1)
            : Rectangle.Empty;
    }

    private static PointF FindHeadAnchor(Bitmap bitmap)
    {
        bool[] skinMask = new bool[bitmap.Width * bitmap.Height];
        for (int y = 0; y < bitmap.Height; y++)
        {
            for (int x = 0; x < bitmap.Width; x++)
            {
                Color color = bitmap.GetPixel(x, y);
                skinMask[y * bitmap.Width + x] =
                    color.A >= 48 &&
                    color.R >= 155 &&
                    color.G >= 105 &&
                    color.B >= 80 &&
                    color.R >= color.G + 12 &&
                    color.G >= color.B + 5;
            }
        }

        List<Component> components = FindComponents(bitmap, skinMask);
        Component head = null;
        foreach (Component component in components)
        {
            int width = component.MaxX - component.MinX + 1;
            int height = component.MaxY - component.MinY + 1;
            if (component.Pixels.Count < 120 || width < 18 || height < 18)
            {
                continue;
            }

            if (head == null || component.Pixels.Count > head.Pixels.Count)
            {
                head = component;
            }
        }

        if (head != null)
        {
            return new PointF(
                (head.MinX + head.MaxX) * 0.5f,
                (head.MinY + head.MaxY) * 0.5f);
        }

        Rectangle bounds = FindAlphaBounds(bitmap, 48);
        return bounds.IsEmpty
            ? new PointF(bitmap.Width * 0.5f, bitmap.Height * 0.5f)
            : new PointF(
                bounds.Left + bounds.Width * 0.5f,
                bounds.Top + bounds.Height * 0.25f);
    }

    private static PointF FindFootAnchor(Bitmap bitmap)
    {
        Rectangle bounds = FindAlphaBounds(bitmap, 64);
        if (bounds.IsEmpty)
        {
            return new PointF(bitmap.Width * 0.5f, bitmap.Height * 0.5f);
        }

        int bandTop = Math.Max(
            bounds.Top,
            bounds.Bottom - Math.Max(12, bounds.Height / 8));
        long sumX = 0;
        long count = 0;
        for (int y = bandTop; y < bounds.Bottom; y++)
        {
            for (int x = bounds.Left; x < bounds.Right; x++)
            {
                if (bitmap.GetPixel(x, y).A < 96)
                {
                    continue;
                }

                sumX += x;
                count++;
            }
        }

        float anchorX = count > 0
            ? (float)sumX / count
            : bounds.Left + bounds.Width * 0.5f;
        return new PointF(anchorX, bounds.Bottom - 1);
    }

    public static void RegisterMotionGrid(
        string inputPath,
        string outputPath,
        int columns,
        int rows,
        int targetCellSize,
        string anchorMode)
    {
        using (var source = new Bitmap(inputPath))
        using (var output = new Bitmap(
            columns * targetCellSize,
            rows * targetCellSize,
            PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(output))
        {
            int sourceCellWidth = source.Width / columns;
            int sourceCellHeight = source.Height / rows;
            var cells = new List<Bitmap>();
            var anchors = new List<PointF>();

            for (int row = 0; row < rows; row++)
            {
                for (int column = 0; column < columns; column++)
                {
                    var sourceRect = new Rectangle(
                        column * sourceCellWidth,
                        row * sourceCellHeight,
                        sourceCellWidth,
                        sourceCellHeight);
                    Bitmap cell = source.Clone(sourceRect, PixelFormat.Format32bppArgb);
                    cells.Add(cell);
                    anchors.Add(anchorMode == "feet"
                        ? FindFootAnchor(cell)
                        : FindHeadAnchor(cell));
                }
            }

            PointF referenceAnchor = anchors[0];
            int baseInsetX = (targetCellSize - sourceCellWidth) / 2;
            int baseInsetY = (targetCellSize - sourceCellHeight) / 2;

            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.NearestNeighbor;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;

            for (int index = 0; index < cells.Count; index++)
            {
                int row = index / columns;
                int column = index % columns;
                int shiftX = (int)Math.Round(referenceAnchor.X - anchors[index].X);
                int shiftY = (int)Math.Round(referenceAnchor.Y - anchors[index].Y);
                var targetCell = new Rectangle(
                    column * targetCellSize,
                    row * targetCellSize,
                    targetCellSize,
                    targetCellSize);

                graphics.SetClip(targetCell);
                graphics.DrawImageUnscaled(
                    cells[index],
                    targetCell.X + baseInsetX + shiftX,
                    targetCell.Y + baseInsetY + shiftY);
                graphics.ResetClip();
                cells[index].Dispose();
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void SolidifyCharacterAlpha(string inputPath, string outputPath)
    {
        using (var sourceFile = new Bitmap(inputPath))
        using (var output = new Bitmap(
            sourceFile.Width,
            sourceFile.Height,
            PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(output))
            {
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(sourceFile, 0, 0);
            }

            for (int y = 0; y < output.Height; y++)
            {
                for (int x = 0; x < output.Width; x++)
                {
                    Color color = output.GetPixel(x, y);
                    if (color.A <= 8)
                    {
                        continue;
                    }

                    int max = Math.Max(color.R, Math.Max(color.G, color.B));
                    int min = Math.Min(color.R, Math.Min(color.G, color.B));
                    int spread = max - min;
                    bool neutralSlashEffect =
                        max >= 150 &&
                        min >= 105 &&
                        spread <= 48;
                    if (neutralSlashEffect)
                    {
                        continue;
                    }

                    double alpha = color.A / 255.0;
                    int boostedAlpha = (int)Math.Round(
                        255.0 * (1.0 - Math.Pow(1.0 - alpha, 3.0)));
                    if (color.A >= 96)
                    {
                        boostedAlpha = Math.Max(boostedAlpha, 245);
                    }

                    output.SetPixel(
                        x,
                        y,
                        Color.FromArgb(
                            Math.Min(255, boostedAlpha),
                            color.R,
                            color.G,
                            color.B));
                }
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void TiltHeadsUp(
        string inputPath,
        string outputPath,
        int columns,
        int rows,
        int[] frameIndices,
        float angleDegrees)
    {
        using (var sourceFile = new Bitmap(inputPath))
        using (var output = new Bitmap(
            sourceFile.Width,
            sourceFile.Height,
            PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(output))
            {
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(sourceFile, 0, 0);
            }

            int cellWidth = output.Width / columns;
            int cellHeight = output.Height / rows;
            foreach (int frameIndex in frameIndices)
            {
                int column = frameIndex % columns;
                int row = frameIndex / columns;
                var cellRect = new Rectangle(
                    column * cellWidth,
                    row * cellHeight,
                    cellWidth,
                    cellHeight);

                using (var cell = output.Clone(
                    cellRect,
                    PixelFormat.Format32bppArgb))
                using (var headLayer = new Bitmap(
                    cellWidth,
                    cellHeight,
                    PixelFormat.Format32bppArgb))
                {
                    PointF headAnchor = FindHeadAnchor(cell);
                    bool[] skinMask = new bool[cellWidth * cellHeight];
                    for (int y = 0; y < cellHeight; y++)
                    {
                        for (int x = 0; x < cellWidth; x++)
                        {
                            Color color = cell.GetPixel(x, y);
                            skinMask[y * cellWidth + x] =
                                color.A >= 48 &&
                                color.R >= 155 &&
                                color.G >= 105 &&
                                color.B >= 80 &&
                                color.R >= color.G + 12 &&
                                color.G >= color.B + 5;
                        }
                    }

                    List<Component> components = FindComponents(cell, skinMask);
                    Component head = null;
                    foreach (Component component in components)
                    {
                        int width = component.MaxX - component.MinX + 1;
                        int height = component.MaxY - component.MinY + 1;
                        if (component.Pixels.Count < 120 || width < 18 || height < 18)
                        {
                            continue;
                        }

                        if (head == null || component.Pixels.Count > head.Pixels.Count)
                        {
                            head = component;
                        }
                    }

                    if (head == null)
                    {
                        continue;
                    }

                    float radiusX = Math.Max(12.0f, (head.MaxX - head.MinX + 1) * 0.58f);
                    float radiusY = Math.Max(12.0f, (head.MaxY - head.MinY + 1) * 0.58f);
                    for (int y = Math.Max(0, (int)Math.Floor(headAnchor.Y - radiusY));
                        y <= Math.Min(cellHeight - 1, (int)Math.Ceiling(headAnchor.Y + radiusY));
                        y++)
                    {
                        for (int x = Math.Max(0, (int)Math.Floor(headAnchor.X - radiusX));
                            x <= Math.Min(cellWidth - 1, (int)Math.Ceiling(headAnchor.X + radiusX));
                            x++)
                        {
                            double normalizedX = (x - headAnchor.X) / radiusX;
                            double normalizedY = (y - headAnchor.Y) / radiusY;
                            if (normalizedX * normalizedX + normalizedY * normalizedY > 1.0)
                            {
                                continue;
                            }

                            Color color = cell.GetPixel(x, y);
                            headLayer.SetPixel(x, y, color);
                            cell.SetPixel(x, y, Color.Transparent);
                        }
                    }

                    using (var cellGraphics = Graphics.FromImage(cell))
                    {
                        cellGraphics.CompositingMode = CompositingMode.SourceOver;
                        cellGraphics.CompositingQuality = CompositingQuality.HighQuality;
                        cellGraphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        cellGraphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
                        cellGraphics.TranslateTransform(headAnchor.X, headAnchor.Y);
                        cellGraphics.RotateTransform(angleDegrees);
                        cellGraphics.TranslateTransform(-headAnchor.X, -headAnchor.Y);
                        cellGraphics.DrawImageUnscaled(headLayer, 0, 0);
                        cellGraphics.ResetTransform();
                    }

                    using (var outputGraphics = Graphics.FromImage(output))
                    {
                        outputGraphics.CompositingMode = CompositingMode.SourceCopy;
                        outputGraphics.DrawImageUnscaled(cell, cellRect.X, cellRect.Y);
                    }
                }
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void RemoveGreenKey(string inputPath, string outputPath)
    {
        using (var sourceFile = new Bitmap(inputPath))
        using (var source = new Bitmap(sourceFile.Width, sourceFile.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(source))
            {
                graphics.DrawImageUnscaled(sourceFile, 0, 0);
            }

            for (int y = 0; y < source.Height; y++)
            {
                for (int x = 0; x < source.Width; x++)
                {
                    Color color = source.GetPixel(x, y);
                    int strongestNonGreen = Math.Max(color.R, color.B);
                    int greenExcess = color.G - strongestNonGreen;
                    int alpha = color.A;

                    if (color.G >= 65 && greenExcess >= 25)
                    {
                        float edge = Math.Max(0.0f, Math.Min(1.0f, (80.0f - greenExcess) / 55.0f));
                        alpha = (int)Math.Round(alpha * edge);
                    }

                    if (alpha <= 4)
                    {
                        source.SetPixel(x, y, Color.Transparent);
                        continue;
                    }

                    int cleanedGreen = Math.Min(color.G, Math.Max(color.R, color.B));
                    source.SetPixel(x, y, Color.FromArgb(alpha, color.R, cleanedGreen, color.B));
                }
            }

            source.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void RemoveConnectedDarkBackground(
        string inputPath,
        string outputPath,
        int threshold)
    {
        using (var sourceFile = new Bitmap(inputPath))
        using (var output = new Bitmap(
            sourceFile.Width,
            sourceFile.Height,
            PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(output))
            {
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(sourceFile, 0, 0);
            }

            int width = output.Width;
            int height = output.Height;
            bool[] visited = new bool[width * height];
            var queue = new Queue<int>();

            Action<int, int> enqueueDark = (x, y) =>
            {
                int index = y * width + x;
                if (visited[index])
                {
                    return;
                }

                Color color = output.GetPixel(x, y);
                if (
                    color.A == 0 ||
                    Math.Max(color.R, Math.Max(color.G, color.B)) <= threshold)
                {
                    visited[index] = true;
                    queue.Enqueue(index);
                }
            };

            for (int x = 0; x < width; x++)
            {
                enqueueDark(x, 0);
                enqueueDark(x, height - 1);
            }
            for (int y = 0; y < height; y++)
            {
                enqueueDark(0, y);
                enqueueDark(width - 1, y);
            }

            while (queue.Count > 0)
            {
                int index = queue.Dequeue();
                int x = index % width;
                int y = index / width;
                output.SetPixel(x, y, Color.Transparent);

                if (x > 0)
                {
                    enqueueDark(x - 1, y);
                }
                if (x + 1 < width)
                {
                    enqueueDark(x + 1, y);
                }
                if (y > 0)
                {
                    enqueueDark(x, y - 1);
                }
                if (y + 1 < height)
                {
                    enqueueDark(x, y + 1);
                }
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void BuildGameWeapon(string inputPath, string outputPath)
    {
        using (var source = new Bitmap(inputPath))
        using (var output = new Bitmap(1536, 1024, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(output))
        {
            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;

            // Match the old shuttle's diagonal footprint so existing sheathed-pose
            // animation tracks remain valid while the new handle stays proportionally longer.
            graphics.TranslateTransform(834.0f, 501.0f);
            graphics.RotateTransform(155.0f);
            graphics.ScaleTransform(0.70f, 0.70f);
            graphics.TranslateTransform(-source.Width / 2.0f, -source.Height / 2.0f);
            graphics.DrawImageUnscaled(source, 0, 0);
            graphics.ResetTransform();

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    private static List<Component> FindComponents(Bitmap bitmap, bool[] mask)
    {
        int width = bitmap.Width;
        int height = bitmap.Height;
        bool[] visited = new bool[mask.Length];
        var components = new List<Component>();
        int[] queue = new int[mask.Length];

        for (int start = 0; start < mask.Length; start++)
        {
            if (!mask[start] || visited[start])
            {
                continue;
            }

            var component = new Component();
            int read = 0;
            int write = 0;
            queue[write++] = start;
            visited[start] = true;

            while (read < write)
            {
                int index = queue[read++];
                int x = index % width;
                int y = index / width;
                Color color = bitmap.GetPixel(x, y);
                component.Add(index, x, y, color);

                for (int oy = -1; oy <= 1; oy++)
                {
                    for (int ox = -1; ox <= 1; ox++)
                    {
                        if (ox == 0 && oy == 0)
                        {
                            continue;
                        }

                        int nx = x + ox;
                        int ny = y + oy;
                        if (nx < 0 || nx >= width || ny < 0 || ny >= height)
                        {
                            continue;
                        }

                        int next = ny * width + nx;
                        if (mask[next] && !visited[next])
                        {
                            visited[next] = true;
                            queue[write++] = next;
                        }
                    }
                }
            }

            components.Add(component);
        }

        return components;
    }

    private static int RectangleDistanceSquared(Component first, Component second)
    {
        int dx = 0;
        if (first.MaxX < second.MinX)
        {
            dx = second.MinX - first.MaxX;
        }
        else if (second.MaxX < first.MinX)
        {
            dx = first.MinX - second.MaxX;
        }

        int dy = 0;
        if (first.MaxY < second.MinY)
        {
            dy = second.MinY - first.MaxY;
        }
        else if (second.MaxY < first.MinY)
        {
            dy = first.MinY - second.MaxY;
        }

        return dx * dx + dy * dy;
    }

    private static bool PointInPolygon(int x, int y, int[] polygon)
    {
        bool inside = false;
        int pointCount = polygon.Length / 2;
        for (int current = 0, previous = pointCount - 1;
            current < pointCount;
            previous = current++)
        {
            int currentX = polygon[current * 2];
            int currentY = polygon[current * 2 + 1];
            int previousX = polygon[previous * 2];
            int previousY = polygon[previous * 2 + 1];

            bool crosses = (currentY > y) != (previousY > y);
            if (crosses)
            {
                double edgeX = previousX +
                    (double)(currentX - previousX) *
                    (y - previousY) /
                    (currentY - previousY);
                if (x < edgeX)
                {
                    inside = !inside;
                }
            }
        }

        return inside;
    }

    public static void RecolorAirWeapon(
        string inputPath,
        string outputPath,
        int columns,
        int rows,
        bool useHandFallback)
    {
        RecolorAirWeapon(
            inputPath,
            outputPath,
            columns,
            rows,
            useHandFallback,
            false);
    }

    public static void RecolorAirWeapon(
        string inputPath,
        string outputPath,
        int columns,
        int rows,
        bool useHandFallback,
        bool preserveBroadVfx)
    {
        using (var sourceFile = new Bitmap(inputPath))
        using (var output = new Bitmap(sourceFile.Width, sourceFile.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(output))
            {
                graphics.DrawImageUnscaled(sourceFile, 0, 0);
            }

            int cellWidth = output.Width / columns;
            int cellHeight = output.Height / rows;

            for (int row = 0; row < rows; row++)
            {
                for (int column = 0; column < columns; column++)
                {
                    using (var cell = output.Clone(
                        new Rectangle(column * cellWidth, row * cellHeight, cellWidth, cellHeight),
                        PixelFormat.Format32bppArgb))
                    {
                        bool[] silverMask = new bool[cellWidth * cellHeight];
                        bool[] purpleMask = new bool[cellWidth * cellHeight];
                        bool[] skinMask = new bool[cellWidth * cellHeight];

                        for (int y = 0; y < cellHeight; y++)
                        {
                            for (int x = 0; x < cellWidth; x++)
                            {
                                int index = y * cellWidth + x;
                                Color color = cell.GetPixel(x, y);
                                int max = Math.Max(color.R, Math.Max(color.G, color.B));
                                int min = Math.Min(color.R, Math.Min(color.G, color.B));
                                int spread = max - min;

                                silverMask[index] =
                                    color.A > 28 &&
                                    max > 55 &&
                                    spread < 72 &&
                                    color.B >= color.G - 2 &&
                                    color.R >= color.G - 12;

                                purpleMask[index] =
                                    color.A > 35 &&
                                    max > 42 &&
                                    color.B > color.G + 5 &&
                                    color.R > color.G + 1;

                                skinMask[index] =
                                    color.A > 50 &&
                                    color.R > 140 &&
                                    color.G > 95 &&
                                    color.B > 68 &&
                                    color.R > color.G + 12 &&
                                    color.G > color.B + 5 &&
                                    color.R > color.B + 30;
                            }
                        }

                        List<Component> silverComponents = FindComponents(cell, silverMask);
                        List<Component> purpleComponents = FindComponents(cell, purpleMask);
                        List<Component> skinComponents = FindComponents(cell, skinMask);
                        var handComponents = new List<Component>();
                        Component largestSkinComponent = null;

                        foreach (Component skin in skinComponents)
                        {
                            if (largestSkinComponent == null ||
                                skin.Pixels.Count > largestSkinComponent.Pixels.Count)
                            {
                                largestSkinComponent = skin;
                            }
                        }

                        foreach (Component skin in skinComponents)
                        {
                            int width = skin.MaxX - skin.MinX + 1;
                            int height = skin.MaxY - skin.MinY + 1;
                            if (skin != largestSkinComponent &&
                                skin.Pixels.Count >= 18 &&
                                skin.Pixels.Count <= 2600 &&
                                width <= 86 &&
                                height <= 86)
                            {
                                handComponents.Add(skin);
                            }
                        }

                        var weaponPurpleComponents = new List<Component>();
                        Component strongestPurpleComponent = null;
                        foreach (Component purple in purpleComponents)
                        {
                            int width = purple.MaxX - purple.MinX + 1;
                            int height = purple.MaxY - purple.MinY + 1;
                            if (purple.Pixels.Count < 8 ||
                                purple.Pixels.Count > 3200 ||
                                width > 280 ||
                                height > 280)
                            {
                                continue;
                            }

                            if (strongestPurpleComponent == null ||
                                purple.Pixels.Count > strongestPurpleComponent.Pixels.Count)
                            {
                                strongestPurpleComponent = purple;
                            }
                        }

                        if (strongestPurpleComponent != null)
                        {
                            weaponPurpleComponents.Add(strongestPurpleComponent);
                        }

                        var recolorPixels = new HashSet<int>();
                        foreach (Component purple in weaponPurpleComponents)
                        {
                            foreach (int index in purple.Pixels)
                            {
                                recolorPixels.Add(index);
                            }
                        }

                        if (strongestPurpleComponent != null)
                        {
                            int metalSearchRadius = preserveBroadVfx ? 18 : 90;
                            for (int y = Math.Max(0, strongestPurpleComponent.MinY - metalSearchRadius);
                                y <= Math.Min(
                                    cellHeight - 1,
                                    strongestPurpleComponent.MaxY + metalSearchRadius);
                                y++)
                            {
                                for (int x = Math.Max(
                                        0,
                                        strongestPurpleComponent.MinX - metalSearchRadius);
                                    x <= Math.Min(
                                        cellWidth - 1,
                                        strongestPurpleComponent.MaxX + metalSearchRadius);
                                    x++)
                                {
                                    int index = y * cellWidth + x;
                                    if (silverMask[index])
                                    {
                                        recolorPixels.Add(index);
                                    }
                                }
                            }
                        }

                        // If a blade rim merges into the sleeve, the purple-component
                        // locator can miss it. Pale hand components provide a safe
                        // secondary anchor; the stricter silver mask excludes the warm
                        // slash VFX and the bronze costume details.
                        if (useHandFallback)
                        {
                            foreach (Component hand in handComponents)
                            {
                                for (int y = Math.Max(0, hand.MinY - 150);
                                    y <= Math.Min(cellHeight - 1, hand.MaxY + 150);
                                    y++)
                                {
                                    for (int x = Math.Max(0, hand.MinX - 150);
                                        x <= Math.Min(cellWidth - 1, hand.MaxX + 150);
                                        x++)
                                    {
                                        int index = y * cellWidth + x;
                                        if (silverMask[index])
                                        {
                                            recolorPixels.Add(index);
                                        }
                                    }
                                }
                            }
                        }

                        // Two air poses place the purple blade against a larger
                        // costume component. Their compact seed regions recolor only
                        // cool/lavender metal pixels, leaving the neutral white arc
                        // behind the weapon untouched.
                        if (!preserveBroadVfx &&
                            !useHandFallback &&
                            ((row == 1 && column == 3) || (row == 2 && column == 5)))
                        {
                            int[] bladePolygon = row == 1
                                ? new int[] {
                                    300, 0,
                                    570, 0,
                                    610, 110,
                                    525, 180,
                                    390, 130,
                                    320, 55
                                }
                                : new int[] {
                                    30, 450,
                                    75, 365,
                                    200, 310,
                                    330, 350,
                                    300, 425,
                                    190, 500,
                                    75, 535
                                };
                            int seedMinX = row == 1 ? 295 : 25;
                            int seedMaxX = row == 1 ? 615 : 335;
                            int seedMinY = row == 1 ? 0 : 305;
                            int seedMaxY = row == 1 ? 185 : 540;

                            for (int y = seedMinY; y <= Math.Min(cellHeight - 1, seedMaxY); y++)
                            {
                                for (int x = seedMinX; x <= Math.Min(cellWidth - 1, seedMaxX); x++)
                                {
                                    int index = y * cellWidth + x;
                                    if (PointInPolygon(x, y, bladePolygon) &&
                                        (purpleMask[index] || silverMask[index]))
                                    {
                                        recolorPixels.Add(index);
                                    }
                                }
                            }
                        }

                        // The final recovery pose places the enlarged blade against the
                        // sleeve, merging its purple rim into the costume component.
                        // Keep a bounded fallback for that one known frame.
                        if (!preserveBroadVfx && row == 4 && column == 5)
                        {
                            for (int y = 245; y <= Math.Min(cellHeight - 1, 535); y++)
                            {
                                for (int x = 0; x <= Math.Min(cellWidth - 1, 350); x++)
                                {
                                    int index = y * cellWidth + x;
                                    if (silverMask[index] || purpleMask[index])
                                    {
                                        recolorPixels.Add(index);
                                    }
                                }
                            }
                        }

                        foreach (int index in recolorPixels)
                        {
                            int x = index % cellWidth;
                            int y = index / cellWidth;
                            Color color = cell.GetPixel(x, y);
                            double luminance = (0.30 * color.R + 0.59 * color.G + 0.11 * color.B) / 255.0;
                            int red = Math.Min(255, (int)Math.Round(38 + 217 * luminance));
                            int green = Math.Min(255, (int)Math.Round(20 + 145 * luminance));
                            int blue = Math.Min(255, (int)Math.Round(8 + 62 * luminance));
                            cell.SetPixel(x, y, Color.FromArgb(color.A, red, green, blue));
                        }

                        using (var graphics = Graphics.FromImage(output))
                        {
                            graphics.CompositingMode = CompositingMode.SourceCopy;
                            graphics.DrawImageUnscaled(cell, column * cellWidth, row * cellHeight);
                        }
                    }
                }
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }

    private static Rectangle FindHeadBounds(Bitmap bitmap)
    {
        bool[] skinMask = new bool[bitmap.Width * bitmap.Height];
        for (int y = 0; y < bitmap.Height; y++)
        {
            for (int x = 0; x < bitmap.Width; x++)
            {
                Color color = bitmap.GetPixel(x, y);
                skinMask[y * bitmap.Width + x] =
                    color.A >= 48 &&
                    color.R >= 155 &&
                    color.G >= 105 &&
                    color.B >= 80 &&
                    color.R >= color.G + 12 &&
                    color.G >= color.B + 5;
            }
        }

        List<Component> components = FindComponents(bitmap, skinMask);
        Component head = null;
        foreach (Component component in components)
        {
            int width = component.MaxX - component.MinX + 1;
            int height = component.MaxY - component.MinY + 1;
            float centerX = (component.MinX + component.MaxX) * 0.5f;
            float centerY = (component.MinY + component.MaxY) * 0.5f;
            if (
                component.Pixels.Count < 120 ||
                width < 18 ||
                height < 18 ||
                width > bitmap.Width * 0.16f ||
                height > bitmap.Height * 0.16f ||
                centerX < bitmap.Width * 0.28f ||
                centerY > bitmap.Height * 0.55f)
            {
                continue;
            }

            if (head == null || component.Pixels.Count > head.Pixels.Count)
            {
                head = component;
            }
        }

        return head == null
            ? Rectangle.Empty
            : Rectangle.FromLTRB(
                head.MinX,
                head.MinY,
                head.MaxX + 1,
                head.MaxY + 1);
    }

    private static bool IsBeltBrown(Color color)
    {
        return
            color.A >= 72 &&
            color.R >= 48 &&
            color.R <= 205 &&
            color.G >= 24 &&
            color.G <= 145 &&
            color.B >= 12 &&
            color.B <= 115 &&
            color.R >= color.G + 10 &&
            color.G >= color.B;
    }

    private static PointF FindBeltAnchor(Bitmap bitmap, Rectangle headBounds)
    {
        if (headBounds.IsEmpty)
        {
            Rectangle bounds = FindAlphaBounds(bitmap, 48);
            return bounds.IsEmpty
                ? new PointF(bitmap.Width * 0.5f, bitmap.Height * 0.55f)
                : new PointF(
                    bounds.Left + bounds.Width * 0.5f,
                    bounds.Top + bounds.Height * 0.48f);
        }

        float headCenterX = headBounds.Left + headBounds.Width * 0.5f;
        int minX = Math.Max(0, (int)Math.Floor(headCenterX - bitmap.Width * 0.24f));
        int maxX = Math.Min(bitmap.Width - 1, (int)Math.Ceiling(headCenterX + bitmap.Width * 0.24f));
        float expectedY = headBounds.Bottom + bitmap.Height * 0.11f;
        int minY = Math.Max(
            headBounds.Bottom + 4,
            (int)Math.Floor(expectedY - bitmap.Height * 0.04f));
        int maxY = Math.Min(
            bitmap.Height - 1,
            (int)Math.Ceiling(expectedY + bitmap.Height * 0.07f));

        int bestY = Math.Min(bitmap.Height - 1, (int)Math.Round(expectedY));
        double bestScore = double.MinValue;
        for (int y = minY; y <= maxY; y++)
        {
            int count = 0;
            for (int x = minX; x <= maxX; x++)
            {
                if (IsBeltBrown(bitmap.GetPixel(x, y)))
                {
                    count++;
                }
            }

            double score = count - Math.Abs(y - expectedY) * 1.5;
            if (score > bestScore)
            {
                bestScore = score;
                bestY = y;
            }
        }

        long sumX = 0;
        long countX = 0;
        for (int y = Math.Max(minY, bestY - 5); y <= Math.Min(maxY, bestY + 5); y++)
        {
            for (int x = minX; x <= maxX; x++)
            {
                if (!IsBeltBrown(bitmap.GetPixel(x, y)))
                {
                    continue;
                }

                sumX += x;
                countX++;
            }
        }

        float beltX = countX > 0 ? (float)sumX / countX : headCenterX;
        return new PointF(beltX, bestY);
    }

    private static bool[] FindLowerBodyMask(
        Bitmap cell,
        PointF beltAnchor,
        float scale,
        float hipHalfWidth,
        float beltOffset)
    {
        int width = cell.Width;
        int height = cell.Height;
        int cutY = Math.Max(
            0,
            Math.Min(
                height - 1,
                (int)Math.Round(beltAnchor.Y + beltOffset * scale)));
        bool[] candidate = new bool[width * height];
        for (int y = cutY; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                candidate[y * width + x] = cell.GetPixel(x, y).A > 0;
            }
        }

        bool[] mask = new bool[width * height];
        int hipDepth = Math.Max(6, (int)Math.Round(28.0f * scale));
        float scaledHipHalfWidth = hipHalfWidth * scale;
        List<Component> components = FindComponents(cell, candidate);
        foreach (Component component in components)
        {
            bool joinsWaist = false;
            foreach (int index in component.Pixels)
            {
                int x = index % width;
                int y = index / width;
                if (
                    y <= cutY + hipDepth &&
                    Math.Abs(x - beltAnchor.X) <= scaledHipHalfWidth)
                {
                    joinsWaist = true;
                    break;
                }
            }

            if (!joinsWaist)
            {
                continue;
            }

            foreach (int index in component.Pixels)
            {
                mask[index] = true;
            }
        }

        bool[] expanded = (bool[])mask.Clone();
        int fringeRadius = Math.Max(1, (int)Math.Ceiling(3.0f * scale));
        for (int y = cutY; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                if (!mask[y * width + x])
                {
                    continue;
                }

                for (int offsetY = -fringeRadius; offsetY <= fringeRadius; offsetY++)
                {
                    int fringeY = y + offsetY;
                    if (fringeY < cutY || fringeY >= height)
                    {
                        continue;
                    }

                    for (int offsetX = -fringeRadius; offsetX <= fringeRadius; offsetX++)
                    {
                        int fringeX = x + offsetX;
                        if (fringeX < 0 || fringeX >= width)
                        {
                            continue;
                        }

                        if (cell.GetPixel(fringeX, fringeY).A > 0)
                        {
                            expanded[fringeY * width + fringeX] = true;
                        }
                    }
                }
            }
        }

        return expanded;
    }

    private static bool[] FindWeaponPreserveMask(
        Bitmap cell,
        PointF beltAnchor,
        float scale)
    {
        int width = cell.Width;
        int height = cell.Height;
        bool[] bronzeMask = new bool[width * height];
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                bronzeMask[y * width + x] = IsBeltBrown(cell.GetPixel(x, y));
            }
        }

        Component weapon = null;
        double bestScore = double.MinValue;
        foreach (Component component in FindComponents(cell, bronzeMask))
        {
            int componentWidth = component.MaxX - component.MinX + 1;
            int componentHeight = component.MaxY - component.MinY + 1;
            int span = Math.Max(componentWidth, componentHeight);
            if (
                component.Pixels.Count < Math.Max(12, 36 * scale * scale) ||
                span < 55.0f * scale)
            {
                continue;
            }

            float centerX = (component.MinX + component.MaxX) * 0.5f;
            float centerY = (component.MinY + component.MaxY) * 0.5f;
            bool compactLowerCostume =
                centerY > beltAnchor.Y + 65.0f * scale &&
                Math.Abs(centerX - beltAnchor.X) < 175.0f * scale;
            if (compactLowerCostume)
            {
                continue;
            }

            double distanceFromBelt = Math.Sqrt(
                Math.Pow(centerX - beltAnchor.X, 2) +
                Math.Pow(centerY - beltAnchor.Y, 2));
            double score =
                span +
                distanceFromBelt * 0.20 +
                component.Pixels.Count * 0.01;
            if (score > bestScore)
            {
                weapon = component;
                bestScore = score;
            }
        }

        bool[] preserve = new bool[width * height];
        if (weapon == null)
        {
            return preserve;
        }

        int padding = Math.Max(3, (int)Math.Round(12.0f * scale));
        foreach (int index in weapon.Pixels)
        {
            int weaponX = index % width;
            int weaponY = index / width;
            for (int offsetY = -padding; offsetY <= padding; offsetY++)
            {
                int preserveY = weaponY + offsetY;
                if (preserveY < 0 || preserveY >= height)
                {
                    continue;
                }

                for (int offsetX = -padding; offsetX <= padding; offsetX++)
                {
                    int preserveX = weaponX + offsetX;
                    if (
                        preserveX < 0 ||
                        preserveX >= width ||
                        offsetX * offsetX + offsetY * offsetY > padding * padding)
                    {
                        continue;
                    }

                    if (cell.GetPixel(preserveX, preserveY).A > 0)
                    {
                        preserve[preserveY * width + preserveX] = true;
                    }
                }
            }
        }

        return preserve;
    }

    private static Rectangle FindStationaryHeadBounds(
        string inputPath,
        int frameIndex,
        Bitmap cell)
    {
        if (inputPath.EndsWith(
            "grounded_double_attack_03_sheet.png",
            StringComparison.OrdinalIgnoreCase))
        {
            if (frameIndex == 10)
            {
                return new Rectangle(340, 160, 60, 70);
            }
        }
        else if (inputPath.EndsWith(
            "grounded_double_attack_04_sheet.png",
            StringComparison.OrdinalIgnoreCase))
        {
            if (frameIndex == 10)
            {
                return new Rectangle(345, 155, 60, 70);
            }
            if (frameIndex == 12)
            {
                return new Rectangle(330, 150, 65, 70);
            }
            if (frameIndex == 14)
            {
                return new Rectangle(370, 190, 60, 70);
            }
        }

        return FindHeadBounds(cell);
    }

    private static void RemoveStationaryFragments(Bitmap bitmap)
    {
        int width = bitmap.Width;
        int height = bitmap.Height;
        bool[] alphaMask = new bool[width * height];
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                alphaMask[y * width + x] = bitmap.GetPixel(x, y).A > 0;
            }
        }

        int fragmentLimit = Math.Max(
            256,
            (int)Math.Round(width * height * 0.004));
        foreach (Component component in FindComponents(bitmap, alphaMask))
        {
            if (component.Pixels.Count >= fragmentLimit)
            {
                continue;
            }

            bool preserve = false;
            foreach (int index in component.Pixels)
            {
                int x = index % width;
                int y = index / width;
                Color color = bitmap.GetPixel(x, y);
                int maximum = Math.Max(color.R, Math.Max(color.G, color.B));
                int minimum = Math.Min(color.R, Math.Min(color.G, color.B));
                bool paleEffect =
                    color.A >= 24 &&
                    minimum >= 105 &&
                    maximum - minimum <= 62;
                bool skin =
                    color.A >= 48 &&
                    color.R >= 155 &&
                    color.G >= 105 &&
                    color.B >= 80 &&
                    color.R >= color.G + 12 &&
                    color.G >= color.B + 5;
                if (paleEffect || skin)
                {
                    preserve = true;
                    break;
                }
            }

            if (preserve)
            {
                continue;
            }

            foreach (int index in component.Pixels)
            {
                bitmap.SetPixel(
                    index % width,
                    index / width,
                    Color.Transparent);
            }
        }
    }

    public static void BuildStationaryGrid(
        string inputPath,
        string stancePath,
        string outputPath,
        int columns,
        int rows)
    {
        using (var source = new Bitmap(inputPath))
        using (var stance = new Bitmap(stancePath))
        using (var stanceLower = new Bitmap(
            stance.Width,
            stance.Height,
            PixelFormat.Format32bppArgb))
        using (var output = new Bitmap(
            source.Width,
            source.Height,
            PixelFormat.Format32bppArgb))
        {
            int cellWidth = source.Width / columns;
            int cellHeight = source.Height / rows;
            Rectangle stanceHead = FindHeadBounds(stance);
            PointF stanceBelt = FindBeltAnchor(stance, stanceHead);
            bool[] stanceLowerMask = FindLowerBodyMask(
                stance,
                stanceBelt,
                1.0f,
                155.0f,
                -12.0f);
            for (int y = 0; y < stance.Height; y++)
            {
                for (int x = 0; x < stance.Width; x++)
                {
                    if (stanceLowerMask[y * stance.Width + x])
                    {
                        stanceLower.SetPixel(x, y, stance.GetPixel(x, y));
                    }
                }
            }

            using (var outputGraphics = Graphics.FromImage(output))
            {
                outputGraphics.Clear(Color.Transparent);
            }

            for (int row = 0; row < rows; row++)
            {
                for (int column = 0; column < columns; column++)
                {
                    var sourceRect = new Rectangle(
                        column * cellWidth,
                        row * cellHeight,
                        cellWidth,
                        cellHeight);
                    using (var cell = source.Clone(sourceRect, PixelFormat.Format32bppArgb))
                    using (var upper = new Bitmap(cellWidth, cellHeight, PixelFormat.Format32bppArgb))
                    using (var composed = new Bitmap(cellWidth, cellHeight, PixelFormat.Format32bppArgb))
                    {
                        int frameIndex = row * columns + column;
                        Rectangle cellHead = FindStationaryHeadBounds(
                            inputPath,
                            frameIndex,
                            cell);
                        PointF cellBelt = FindBeltAnchor(cell, cellHead);
                        float scale = stanceHead.IsEmpty || cellHead.IsEmpty
                            ? (float)cellHeight / stance.Height
                            : (float)cellHead.Height / stanceHead.Height;
                        scale = Math.Max(0.25f, Math.Min(0.85f, scale));
                        bool[] lowerMask = FindLowerBodyMask(
                            cell,
                            cellBelt,
                            scale,
                            180.0f,
                            18.0f);
                        bool isBronzeWeaponSheet =
                            inputPath.EndsWith(
                                "grounded_double_attack_01_sheet.png",
                                StringComparison.OrdinalIgnoreCase) ||
                            inputPath.EndsWith(
                                "grounded_double_attack_02_sheet.png",
                                StringComparison.OrdinalIgnoreCase);
                        bool[] weaponPreserveMask = isBronzeWeaponSheet
                            ? FindWeaponPreserveMask(cell, cellBelt, scale)
                            : new bool[cellWidth * cellHeight];
                        for (int y = 0; y < cellHeight; y++)
                        {
                            for (int x = 0; x < cellWidth; x++)
                            {
                                Color original = cell.GetPixel(x, y);
                                int maximum = Math.Max(
                                    original.R,
                                    Math.Max(original.G, original.B));
                                int minimum = Math.Min(
                                    original.R,
                                    Math.Min(original.G, original.B));
                                bool paleEffect =
                                    original.A >= 24 &&
                                    minimum >= 105 &&
                                    maximum - minimum <= 62;
                                if (
                                    !lowerMask[y * cellWidth + x] ||
                                    paleEffect ||
                                    weaponPreserveMask[y * cellWidth + x])
                                {
                                    upper.SetPixel(x, y, original);
                                }
                            }
                        }

                        using (var graphics = Graphics.FromImage(composed))
                        {
                            graphics.Clear(Color.Transparent);
                            graphics.CompositingMode = CompositingMode.SourceOver;
                            graphics.CompositingQuality = CompositingQuality.HighQuality;
                            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;

                            int destinationX = (int)Math.Round(
                                cellBelt.X - stanceBelt.X * scale);
                            int destinationY = (int)Math.Round(
                                cellBelt.Y - stanceBelt.Y * scale);
                            var destination = new Rectangle(
                                destinationX,
                                destinationY,
                                (int)Math.Round(stance.Width * scale),
                                (int)Math.Round(stance.Height * scale));
                            var stanceSource = new Rectangle(
                                0,
                                0,
                                stance.Width,
                                stance.Height);
                            graphics.DrawImage(
                                stanceLower,
                                destination,
                                stanceSource,
                                GraphicsUnit.Pixel);
                            graphics.DrawImageUnscaled(upper, 0, 0);
                        }

                        RemoveStationaryFragments(composed);
                        using (var graphics = Graphics.FromImage(output))
                        {
                            graphics.CompositingMode = CompositingMode.SourceCopy;
                            graphics.DrawImageUnscaled(
                                composed,
                                column * cellWidth,
                                row * cellHeight);
                        }
                    }
                }
            }

            output.Save(outputPath, ImageFormat.Png);
        }
    }
}
'@

Add-Type -TypeDefinition $normalizerSource -ReferencedAssemblies System.Drawing

function Copy-NormalizedAsset {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $sourcePath = Join-Path $projectRoot $Source
    $destinationPath = Join-Path $projectRoot $Destination
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
}

Copy-NormalizedAsset "Assets\Threadborne\Idle\Idleright.png" "Assets\Threadborne\Player\Normalized_V2\idle\idle_right.png"

$runFrames = @(1, 2, 3, 4, 5, 6, 7, 8, 12, 18, 20)
foreach ($frame in $runFrames) {
    $sourceName = "Assets\Threadborne\Run\ezgif-frame-{0:D3}.png" -f $frame
    $destinationName = "Assets\Threadborne\Player\Normalized_V2\run\run_{0:D3}.png" -f $frame
    Copy-NormalizedAsset $sourceName $destinationName
}

$copyMap = @{
    "Assets\Threadborne\Player_Normalized_V1\Jump_Ascent.png" = "Assets\Threadborne\Player\Normalized_V2\jump\ascent.png"
    "Assets\Threadborne\Player_Normalized_V1\Jump_Apex.png" = "Assets\Threadborne\Player\Normalized_V2\jump\apex.png"
    "Assets\Threadborne\Player_Normalized_V1\Jump_Descent.png" = "Assets\Threadborne\Player\Normalized_V2\jump\descent.png"
    "Assets\Threadborne\Player_Normalized_V1\Jump_Land.png" = "Assets\Threadborne\Player\Normalized_V2\jump\land.png"
    "Assets\Threadborne\Player_Normalized_V1\Grapple_Toss_Right.png" = "Assets\Threadborne\Player\Normalized_V2\grapple\toss_horizontal.png"
    "Assets\Threadborne\Player_Normalized_V1\Grapple_Toss_Diag_Right.png" = "Assets\Threadborne\Player\Normalized_V2\grapple\toss_diagonal.png"
    "Assets\Threadborne\Dash\dash_frame_normalized.png" = "Assets\Threadborne\Player\Normalized_V2\movement\dash.png"
    "Assets\Threadborne\Player_Normalized_V1\Wall_Cling.png" = "Assets\Threadborne\Player\Normalized_V2\movement\wall_cling.png"
}

foreach ($source in $copyMap.Keys) {
    Copy-NormalizedAsset $source $copyMap[$source]
}

$ledgeHangPath = Join-Path $outputRoot "movement\ledge_hang.png"
if (-not (Test-Path -LiteralPath $ledgeHangPath)) {
    throw "Missing ledge hang sheet: $ledgeHangPath"
}
$transparentLedgeHangPath = "$ledgeHangPath.transparent.png"
[ThreadboundAnimationNormalizer]::RemoveConnectedDarkBackground(
    $ledgeHangPath,
    $transparentLedgeHangPath,
    3)
Move-Item `
    -LiteralPath $transparentLedgeHangPath `
    -Destination $ledgeHangPath `
    -Force

function Resolve-FfmpegExecutable {
    if ($FfmpegPath) {
        return (Resolve-Path -LiteralPath $FfmpegPath).Path
    }

    $ffmpegCommand = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpegCommand) {
        return $ffmpegCommand.Source
    }

    $knownFfmpegPaths = @(
        "C:\Program Files\Krita (x64)\bin\ffmpeg.exe",
        "C:\Program Files\ffmpeg\bin\ffmpeg.exe"
    )
    foreach ($knownPath in $knownFfmpegPaths) {
        if (Test-Path -LiteralPath $knownPath) {
            return $knownPath
        }
    }

    throw "FFmpeg was not found. Pass -FfmpegPath when rebuilding video attack sheets."
}

function New-VideoAttackSheets {
    param(
        [Parameter(Mandatory = $true)][string]$VideoPath,
        [Parameter(Mandatory = $true)][array]$SheetJobs
    )

    $resolvedVideoPath = (Resolve-Path -LiteralPath $VideoPath).Path
    $resolvedFfmpeg = Resolve-FfmpegExecutable
    $temporaryRoot = Join-Path (
        [System.IO.Path]::GetTempPath()
    ) ("threadbound-video-attack-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

    try {
        $framePattern = Join-Path $temporaryRoot "frame_%03d.png"
        & $resolvedFfmpeg `
            -hide_banner `
            -loglevel error `
            -i $resolvedVideoPath `
            -fps_mode passthrough `
            -start_number 0 `
            $framePattern
        if ($LASTEXITCODE -ne 0) {
            throw "FFmpeg failed to extract frames from $resolvedVideoPath."
        }

        foreach ($job in $SheetJobs) {
            $rawGrid = Join-Path $temporaryRoot ("raw_" + [string]$job[0])
            $alphaGrid = Join-Path $temporaryRoot ("alpha_" + [string]$job[0])
            $authoringPath = Join-Path $projectRoot ([string]$job[1])
            [ThreadboundAnimationNormalizer]::BuildSelectedFrameGrid(
                $temporaryRoot,
                $rawGrid,
                [int[]]$job[4],
                [int]$job[2],
                [int]$job[3],
                640)
            [ThreadboundAnimationNormalizer]::RemoveGreenKey($rawGrid, $alphaGrid)
            # The generated attack videos already use one fixed 640 px camera
            # and ground line. Preserve that shared origin so slash VFX cannot
            # be mistaken for a foot anchor and shift the body between frames.
            [ThreadboundAnimationNormalizer]::NormalizeGrid(
                $alphaGrid,
                $authoringPath,
                [int]$job[2],
                [int]$job[3],
                640,
                1.0)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
        }
    }
}

$stationaryVideoSheetJobs = @(
    @(
        "stationary_combo_01.png",
        "Assets\Threadborne\New Attack\Video Attacks\stationary_video_combo_01_sheet.png",
        5,
        5,
        [int[]]@(48, 50, 52, 54, 56, 58, 60, 62, 64, 66, 69, 73, 77, 80)
    ),
    @(
        "stationary_combo_02.png",
        "Assets\Threadborne\New Attack\Video Attacks\stationary_video_combo_02_sheet.png",
        6,
        4,
        [int[]]@(0, 2, 4, 6, 8, 10, 11, 13, 15, 16, 18, 19, 21, 22, 24, 25, 27, 28, 29)
    )
)

$backpedalVideoSheetJobs = @(
    @(
        "backpedal_combo_01.png",
        "Assets\Threadborne\New Attack\Video Attacks\backpedal_video_combo_01_sheet.png",
        5,
        5,
        [int[]]@(0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 40)
    ),
    @(
        "backpedal_combo_02.png",
        "Assets\Threadborne\New Attack\Video Attacks\backpedal_video_combo_02_sheet.png",
        6,
        4,
        [int[]]@(0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36, 40)
    )
)

if ($StationaryAttackVideo) {
    New-VideoAttackSheets `
        -VideoPath $StationaryAttackVideo `
        -SheetJobs $stationaryVideoSheetJobs
}
if ($BackpedalAttackVideo) {
    New-VideoAttackSheets `
        -VideoPath $BackpedalAttackVideo `
        -SheetJobs $backpedalVideoSheetJobs
}

$attackJobs = @(
    @("Assets\Threadborne\New Attack\threadborn_grounded_attack.png", "attacks\ground_forward.png", 6, 8, 1024, 0.75),
    @("Assets\Threadborne\threadborne_smash_attack.png", "attacks\neutral_special.png", 6, 8, 1024, 0.675),
    @("Assets\Threadborne\New Attack\Video Attacks\grounded_double_attack_01_sheet.png", "attacks\ground_combo_01.png", 6, 4, 896, 0.9),
    @("Assets\Threadborne\New Attack\Video Attacks\grounded_double_attack_02_sheet.png", "attacks\ground_combo_02.png", 5, 5, 640, 0.9),
    @("Assets\Threadborne\New Attack\Video Attacks\stationary_video_combo_01_sheet.png", "attacks\stationary_combo_01.png", 5, 5, 640, 0.9),
    @("Assets\Threadborne\New Attack\Video Attacks\stationary_video_combo_02_sheet.png", "attacks\stationary_combo_02.png", 6, 4, 640, 0.9),
    @("Assets\Threadborne\New Attack\Video Attacks\backpedal_video_combo_01_sheet.png", "attacks\backpedal_combo_01.png", 5, 5, 640, 1.15),
    @("Assets\Threadborne\New Attack\Video Attacks\backpedal_video_combo_02_sheet.png", "attacks\backpedal_combo_02.png", 6, 4, 640, 1.15),
    @("Assets\Threadborne\New Attack\Video Attacks\air_double_attack_01_candidate_sheet.png", "attacks\air_double_attack.png", 6, 5, 832, 1.2)
)

foreach ($job in $attackJobs) {
    $sourcePath = Join-Path $projectRoot $job[0]
    $destinationPath = Join-Path $outputRoot $job[1]
    [ThreadboundAnimationNormalizer]::NormalizeGrid(
        $sourcePath,
        $destinationPath,
        [int]$job[2],
        [int]$job[3],
        [int]$job[4],
        [float]$job[5])
}

$motionJobs = @(
    @("ascent", "jump\ascent_cycle.png", 2, 2, "head"),
    @("apex", "jump\apex_cycle.png", 2, 2, "head"),
    @("descent", "jump\descent_cycle.png", 2, 2, "head"),
    @("land", "jump\land_cycle.png", 2, 2, "feet"),
    @("wall_cling", "movement\wall_cling_cycle.png", 2, 2, "head"),
    @("grapple_horizontal", "grapple\toss_horizontal_cycle.png", 3, 2, "feet"),
    @("grapple_diagonal", "grapple\toss_diagonal_cycle.png", 3, 2, "feet")
)

if ($MotionChromaSourceDirectory) {
    $resolvedMotionSourceDirectory = (Resolve-Path $MotionChromaSourceDirectory).Path
    foreach ($motionJob in $motionJobs) {
        $motionName = [string]$motionJob[0]
        $chromaPath = Join-Path $resolvedMotionSourceDirectory "$motionName.chroma.png"
        $alphaPath = Join-Path $resolvedMotionSourceDirectory "$motionName.alpha.png"
        $destinationPath = Join-Path $outputRoot ([string]$motionJob[1])
        $unregisteredPath = "$destinationPath.unregistered.png"

        if (-not (Test-Path -LiteralPath $chromaPath)) {
            throw "Missing motion chroma source: $chromaPath"
        }

        [ThreadboundAnimationNormalizer]::RemoveGreenKey($chromaPath, $alphaPath)
        [ThreadboundAnimationNormalizer]::NormalizeGrid(
            $alphaPath,
            $unregisteredPath,
            [int]$motionJob[2],
            [int]$motionJob[3],
            512,
            1.0)
        [ThreadboundAnimationNormalizer]::RegisterMotionGrid(
            $unregisteredPath,
            $destinationPath,
            [int]$motionJob[2],
            [int]$motionJob[3],
            640,
            [string]$motionJob[4])
        Remove-Item -LiteralPath $alphaPath -Force
        Remove-Item -LiteralPath $unregisteredPath -Force
    }
}

if ($RegisterExistingMotion) {
    foreach ($motionJob in $motionJobs) {
        $destinationPath = Join-Path $outputRoot ([string]$motionJob[1])
        if (-not (Test-Path -LiteralPath $destinationPath)) {
            throw "Missing existing motion sheet: $destinationPath"
        }

        $image = [System.Drawing.Image]::FromFile($destinationPath)
        $alreadyRegistered =
            $image.Width -eq ([int]$motionJob[2] * 640) -and
            $image.Height -eq ([int]$motionJob[3] * 640)
        $alreadyRuntimeOptimized =
            $image.Width -eq ([int]$motionJob[2] * 320) -and
            $image.Height -eq ([int]$motionJob[3] * 320)
        $image.Dispose()
        if ($alreadyRegistered -or $alreadyRuntimeOptimized) {
            Write-Host "Motion sheet already registered: $destinationPath"
            continue
        }

        $registeredPath = "$destinationPath.registered.png"
        [ThreadboundAnimationNormalizer]::RegisterMotionGrid(
            $destinationPath,
            $registeredPath,
            [int]$motionJob[2],
            [int]$motionJob[3],
            640,
            [string]$motionJob[4])
        Move-Item -LiteralPath $registeredPath -Destination $destinationPath -Force
    }
}

$bronzeWeaponSheets = @(
    @("attacks\ground_combo_01.png", 6, 4, $true, $false),
    @("attacks\ground_combo_02.png", 5, 5, $true, $false),
    @("attacks\stationary_combo_01.png", 5, 5, $false, $true),
    @("attacks\stationary_combo_02.png", 6, 4, $false, $true),
    @("attacks\backpedal_combo_01.png", 5, 5, $false, $true),
    @("attacks\backpedal_combo_02.png", 6, 4, $false, $true),
    @("attacks\air_double_attack.png", 6, 5, $false, $false)
)

foreach ($sheet in $bronzeWeaponSheets) {
    $sheetPath = Join-Path $outputRoot $sheet[0]
    $bronzePath = "$sheetPath.bronze.png"
    $opaquePath = "$sheetPath.opaque.png"
    [ThreadboundAnimationNormalizer]::RecolorAirWeapon(
        $sheetPath,
        $bronzePath,
        [int]$sheet[1],
        [int]$sheet[2],
        [bool]$sheet[3],
        [bool]$sheet[4])
    Move-Item -LiteralPath $bronzePath -Destination $sheetPath -Force
    [ThreadboundAnimationNormalizer]::SolidifyCharacterAlpha(
        $sheetPath,
        $opaquePath)
    Move-Item -LiteralPath $opaquePath -Destination $sheetPath -Force
}

if ($WeaponChromaSource) {
    $resolvedWeaponSource = (Resolve-Path $WeaponChromaSource).Path
    [ThreadboundAnimationNormalizer]::RemoveGreenKey($resolvedWeaponSource, $weaponReference)
}

if (-not (Test-Path -LiteralPath $weaponReference)) {
    throw "Missing transparent weapon reference: $weaponReference"
}

$gameWeaponPath = Join-Path $outputRoot "weapon\weavers_shuttle_v3.png"
[ThreadboundAnimationNormalizer]::BuildGameWeapon($weaponReference, $gameWeaponPath)

function Set-RuntimeRasterSize {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][int]$NormalizedWidth,
        [Parameter(Mandatory = $true)][int]$NormalizedHeight
    )

    $assetPath = Join-Path $outputRoot $RelativePath
    if (-not (Test-Path -LiteralPath $assetPath)) {
        throw "Missing normalized runtime asset: $assetPath"
    }

    $runtimeWidth = [int][Math]::Round($NormalizedWidth * 0.5)
    $runtimeHeight = [int][Math]::Round($NormalizedHeight * 0.5)
    $image = [System.Drawing.Image]::FromFile($assetPath)
    $currentWidth = $image.Width
    $currentHeight = $image.Height
    $image.Dispose()

    if ($currentWidth -eq $runtimeWidth -and $currentHeight -eq $runtimeHeight) {
        return
    }

    if ($currentWidth -ne $NormalizedWidth -or $currentHeight -ne $NormalizedHeight) {
        throw (
            "Unexpected dimensions for {0}: {1}x{2}; expected {3}x{4} or {5}x{6}." -f
            $assetPath,
            $currentWidth,
            $currentHeight,
            $NormalizedWidth,
            $NormalizedHeight,
            $runtimeWidth,
            $runtimeHeight
        )
    }

    $runtimePath = "$assetPath.runtime.png"
    [ThreadboundAnimationNormalizer]::ResizeImage(
        $assetPath,
        $runtimePath,
        $runtimeWidth,
        $runtimeHeight)
    Move-Item -LiteralPath $runtimePath -Destination $assetPath -Force
}

# The normalized sources retain enough detail for the intended ~175 px-tall
# presentation. Keeping their full authoring resolution in live atlases made
# the player scene eagerly decode roughly 800 MiB of RGBA pixels, with further
# CPU/GPU copies pushing the game into multi-gigabyte memory use. Halving every
# body-animation raster and doubling the one uniform AnimatedSprite2D scale
# preserves the exact screen-space size while reducing texture area by 75%.
$runtimeRasterAssets = @(
    @("idle\idle_right.png", 3072, 3072),
    @("jump\ascent.png", 512, 512),
    @("jump\apex.png", 512, 512),
    @("jump\descent.png", 512, 512),
    @("jump\land.png", 512, 512),
    @("grapple\toss_horizontal.png", 512, 512),
    @("grapple\toss_diagonal.png", 512, 512),
    @("movement\dash.png", 512, 512),
    @("movement\wall_cling.png", 512, 512),
    @("jump\ascent_cycle.png", 1280, 1280),
    @("jump\apex_cycle.png", 1280, 1280),
    @("jump\descent_cycle.png", 1280, 1280),
    @("jump\land_cycle.png", 1280, 1280),
    @("movement\wall_cling_cycle.png", 1280, 1280),
    @("grapple\toss_horizontal_cycle.png", 1920, 1280),
    @("grapple\toss_diagonal_cycle.png", 1920, 1280),
    @("attacks\ground_forward.png", 6144, 8192),
    @("attacks\neutral_special.png", 6144, 8192),
    @("attacks\ground_combo_01.png", 5376, 3584),
    @("attacks\ground_combo_02.png", 3200, 3200),
    @("attacks\stationary_combo_01.png", 3200, 3200),
    @("attacks\stationary_combo_02.png", 3840, 2560),
    @("attacks\backpedal_combo_01.png", 3200, 3200),
    @("attacks\backpedal_combo_02.png", 3840, 2560),
    @("attacks\air_double_attack.png", 4992, 4160)
)

foreach ($frame in $runFrames) {
    $runtimeRasterAssets += ,@(
        ("run\run_{0:D3}.png" -f $frame),
        1095,
        1095
    )
}

foreach ($runtimeAsset in $runtimeRasterAssets) {
    Set-RuntimeRasterSize `
        -RelativePath ([string]$runtimeAsset[0]) `
        -NormalizedWidth ([int]$runtimeAsset[1]) `
        -NormalizedHeight ([int]$runtimeAsset[2])
}

# Keep intermittent loose cloth out of the jump/grapple silhouettes. Each
# cleanup compares only the shoulder region with a nearby clean reference
# frame, preserving pose-specific pixels everywhere else.
$descentCyclePath = Join-Path $outputRoot "jump\descent_cycle.png"
foreach ($targetFrame in @(1, 2, 3)) {
    $cleanedPath = "$descentCyclePath.cleaned.png"
    [ThreadboundAnimationNormalizer]::ClearPixelsOutsideReference(
        $descentCyclePath,
        $cleanedPath,
        2,
        2,
        0,
        $targetFrame,
        120,
        35,
        95,
        95)
    Move-Item -LiteralPath $cleanedPath -Destination $descentCyclePath -Force
}

# The second descent frame has one additional short tail on the far side of
# the mask, outside the shared shoulder cleanup region above.
$cleanedPath = "$descentCyclePath.cleaned.png"
[ThreadboundAnimationNormalizer]::ClearPixelsOutsideReference(
    $descentCyclePath,
    $cleanedPath,
    2,
    2,
    0,
    1,
    210,
    35,
    50,
    85)
Move-Item -LiteralPath $cleanedPath -Destination $descentCyclePath -Force

# The horizontal follow-through previously ended on a limp, malformed hand.
# Reusing the matching extension pose on the retract beat makes the six-frame
# toss read cleanly in both directions without inventing a new body pose.
$horizontalGrapplePath = Join-Path $outputRoot "grapple\toss_horizontal_cycle.png"
$cleanedHorizontalPath = "$horizontalGrapplePath.cleaned.png"
[ThreadboundAnimationNormalizer]::CopyAnimationFrame(
    $horizontalGrapplePath,
    $cleanedHorizontalPath,
    3,
    2,
    1,
    4)
Move-Item `
    -LiteralPath $cleanedHorizontalPath `
    -Destination $horizontalGrapplePath `
    -Force

Write-Host "Normalized player animation assets written to $outputRoot"
