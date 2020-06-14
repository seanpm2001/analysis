%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
% This file is part of anaLYsis,                                              %
%                      ========                                               %
% a toolkit to highlight analytical results and comments in musical scores,   %
% belonging to openLilyLib (https://github.com/openlilylib                    %
%              -----------                                                    %
%                                                                             %
% anaLYsis is free software: you can redistribute it and/or modify            %
% it under the terms of the GNU General Public License as published by        %
% the Free Software Foundation, either version 3 of the License, or           %
% (at your option) any later version.                                         %
%                                                                             %
% anaLYsis is distributed in the hope that it will be useful,                 %
% but WITHOUT ANY WARRANTY; without even the implied warranty of              %
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               %
% GNU Lesser General Public License for more details.                         %
%                                                                             %
% You should have received a copy of the GNU General Public License           %
% along with anaLYsis.  If not, see <http://www.gnu.org/licenses/>.           %
%                                                                             %
% anaLYsis is maintained by Urs Liska, ul@openlilylib.org                     %
% Copyright Klaus Blum & Urs Liska, 2017                                      %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --------------------------------------------------------------------------
%    Frames and Rectangles
% --------------------------------------------------------------------------

% Define configuration variables and set defaults

\registerOption analysis.highlighters.active ##t
\registerOption analysis.highlighters.color #green
\registerOption analysis.highlighters.thickness #2.0
\registerOption analysis.highlighters.layer #-5
\registerOption analysis.highlighters.X-offset #0.6
\registerOption analysis.highlighters.X-first #-1.2
\registerOption analysis.highlighters.X-last #1.2
\registerOption analysis.highlighters.Y-first #0
\registerOption analysis.highlighters.Y-last #0
\registerOption analysis.highlighters.style #'ramp


#(define (get-highlighter-properties ctx-mod)
   "Process the highlighter's options.
    All properties are initially populated with (default) values
    of the corresponding options and may be overridden with values
    from the actual highlighter's \\with clause."
   (let*
    (
      (props (if ctx-mod
                 (context-mod->props ctx-mod)
                 '()))
      (color
       (let*
        ((prop-col (assq 'color props)))
        (if prop-col
            (cdr prop-col)
            (getOption '(analysis highlighters color)))))

      (thickness
       (or (assq-ref props 'thickness)
           (getOption '(analysis highlighters thickness))))
      (layer
       (or (assq-ref props 'layer)
           (getOption '(analysis highlighters layer))))
      (X-offset
       (or (assq-ref props 'X-offset)
           (getOption '(analysis highlighters X-offset))))
      (X-first
       (or (assq-ref props 'X-first)
           (getOption '(analysis highlighters X-first))))
      (X-last
       (or (assq-ref props 'X-last)
           (getOption '(analysis highlighters X-last))))
      (Y-first
       (or (assq-ref props 'Y-first)
           (getOption '(analysis highlighters Y-first))))
      (Y-last
       (or (assq-ref props 'Y-last)
           (getOption '(analysis highlighters Y-last))))
      (style
       (or (assq-ref props 'style)
           (getOption '(analysis highlighters style))))
      )
    `(
       (color . ,color)
       (thickness . ,thickness)
       (layer . ,layer)
       (X-offset . ,X-offset)
       (X-first . ,X-first)
       (X-last . ,X-last)
       (Y-first . ,Y-first)
       (Y-last . ,Y-last)
       (style . ,style)
       )
    )
   )


#(define (moment->duration moment)
   ;; see duration.cc in Lilypond sources (Duration::Duration)
   ;; http://lsr.di.unimi.it/LSR/Item?id=542
   (let* ((p (ly:moment-main-numerator moment))
          (q (ly:moment-main-denominator moment))
          (k (- (ly:intlog2 q) (ly:intlog2 p)))
          (dots 0))
     ;(ash p k) = p * 2^k
     (if (< (ash p k) q) (set! k (1+ k)))
     (set! p (- (ash p k) q))
     (while (begin (set! p (ash p 1))(>= p q))
       (set! p (- p q))
       (set! dots (1+ dots)))
     (if (> k 6)
         (ly:make-duration 6 0)
         (ly:make-duration k dots))
     ))


#(define (custom-moment->duration moment)
   ;; adapted version to convert ANY moment p/q into duration 1*p/q
   (let* ((p (ly:moment-main-numerator moment))
          (q (ly:moment-main-denominator moment))
          )
     (ly:make-duration 0 0 p q)
     ))


highlight =
#(define-music-function (properties mus)
   ((ly:context-mod?) ly:music?)
   ;; http://lilypond.1069038.n5.nabble.com/Apply-event-function-within-music-function-tp202841p202847.html
   (let*
    (
      (props (get-highlighter-properties properties))
      (mus-elts (ly:music-property mus 'elements))
      ; last music-element:
      (lst (last mus-elts)) ; TODO test for list? and ly:music?
      ; length of entire music expression "mus":
      (len (ly:music-length mus))
      ; length of last element only:
      (last-skip (ly:music-length lst))
      ; difference = length of "mus" except the last element:
      (first-skip (ly:moment-sub len last-skip))
      (color (assq-ref props 'color))
      (thickness (assq-ref props 'thickness))
      (layer (assq-ref props 'layer))
      (X-offset (assq-ref props 'X-offset))
      (X-first (assq-ref props 'X-first))
      (X-last (assq-ref props 'X-last))
      (Y-first (assq-ref props 'Y-first))
      (Y-last (assq-ref props 'Y-last))
      (style (assq-ref props 'style))
      )
    (if (getOption '(analysis highlighters active))
        (make-relative (mus) mus  ;; see http://lilypond.1069038.n5.nabble.com/Current-octave-in-relative-mode-tp232869p232870.html  (thanks, David!)
          #{
            <<
              $mus
              % \new Voice
              \makeClusters {
                \once \override ClusterSpanner.style = $style
                \once \override ClusterSpanner.color = $color
                \once \override ClusterSpanner.padding =
                #(if (< thickness 0.5)
                     (begin (ly:warning "\"thickness\" parameter for \\highlight is below minimum value 0.5 - Replacing with 0.5")
                       0.25)
                     (/ thickness 2))
                \once \override ClusterSpanner.layer = $layer
                \once \override ClusterSpanner.X-offset = $X-offset
                \once \override ClusterSpannerBeacon.X-offset = $X-first
                \once \override ClusterSpannerBeacon.Y-offset = $Y-first
                <<
                  $mus
                  {
                    % skip until last element starts:
                    #(if (not (equal? first-skip (ly:make-moment 0/1 0/1))) ; skip with zero length would cause error
                         (make-music 'SkipEvent 'duration (custom-moment->duration first-skip)))
                    \once \override ClusterSpannerBeacon.X-offset = $X-last
                    \once \override ClusterSpannerBeacon.Y-offset = $Y-last
                  }
                >>
              }
            >>
          #})
        mus
        )))
