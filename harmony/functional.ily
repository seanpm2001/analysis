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
% along with ScholarLY.  If not, see <http://www.gnu.org/licenses/>.          %
%                                                                             %
% anaLYsis is maintained by Urs Liska, ul@openlilylib.org                     %
% Copyright Klaus Blum & Urs Liska, 2019                                      %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{
  This file implements support for functional analysis symbols
  Based on code contributed by Malte Meyn.
%}

\version "2.19.65"

\loadModule analysis.harmony

#(use-modules (ice-9 regex))

\definePropertySet analysis.harmony.functional
#`((double-letter-offset ,number-pair? ,(cons 0.37  -0.37))
   (number-size ,number? 0)
   )

#(define-markup-command (function-markup layout props use-preset properties str)
   (boolean? list? string?)
   #:properties ((font-size 0)
                 (font-features '()))
   ; NOTE/TODO:
   ; The variable use-presets is passed on from the (use-preset) function
   ; of the original with-property-set call. It is not respected yet.
   ; The variable properties holds the properties alist from the
   ; original with-property-set calls in \function and \lyricsToFunctions,
   ; *after* processing (i.e. type and preset checking)
   ; this is currently not used within the markup function.
   (let* ((property (lambda (name) (assq-ref properties name)))
          (number-size (- (property 'number-size) 6))
          (v (if (string-match "/" str) #t #f))
          (kl (if (string-match "\\(" str) #t #f))
          (kr (if (string-match "\\)" str) #t #f))
          (el (if (string-match "\\[" str) #t #f))
          (er (if (string-match "\\]" str) #t #f))
          (f-match (string-match "[A-Za-z]+" str))
          (f (if f-match (match:substring f-match) " "))
          (d (and (< 1 (string-length f)) (equal? (string-ref f 0) (string-ref f 1))))
          (t (if d (markup (string (string-ref f 0)))))
          (b-match (string-match "_[0-9]+[<>]?" str))
          (b (if b-match (substring (match:substring b-match) 1) ""))
          (s-match (string-match "\\^[0-9]+[<>]?" str))
          (s (if s-match (substring (match:substring s-match) 1) ""))
          (o-match (list-matches "-([0-9]+[<>]?|n|N|v)" str))
          (o (map (lambda (x) (substring (match:substring x) 1)) o-match))
          (kl-markup (cond
                      (kl "(")
                      (el "[")
                      (else (markup #:null))))
          (kr-markup (cond
                      (kr ")")
                      (er "]")
                      (else (markup #:null))))
          (v-markup (cond
                     ((not v)
                      (markup #:null))
                     ((string-index "st" (string-ref f 0))
                      (markup #:translate '(0. . 0.0)
                        #:draw-line '(0.9 . 1.1)))
                     (else (markup #:translate '(0.0 . -0.1)
                             #:draw-line '(1.3 . 1.7)))))
          (f-markup (if d
                        (markup #:concat
                          (#:combine
                           t #:translate (property 'double-letter-offset) t
                           (substring f 2)))
                        (markup f)))
          (b-markup (markup #:fontsize number-size b))
          (s-markup (markup #:fontsize number-size s))
          (o-markup (map (lambda (x) (markup #:fontsize number-size x)) o))
          (o-markups (case (length o-markup)
                       ((0) (make-list 3 (markup #:null)))
                       ((1) (list (markup #:null) (list-ref o-markup 0) (markup #:null)))
                       ((2) (cons (markup #:null) o-markup))
                       ((3) o-markup))))
     (interpret-markup layout props
       #{
         \markup
         \scale #(cons (magstep font-size) (magstep font-size))
         \override #(cons 'font-features (cons "lnum" font-features))
         \normalsize \concat {
           #kl-markup
           \override #(cons 'baseline-skip
                        (+ 1.2 (if (or d (string-match "[gp]" f)) 0.37 0)))
           \center-column {
             \override #(cons 'direction UP)
             \override #(cons 'baseline-skip
                          (- 2 (if (string-match "^[acegips]*$" f) 0.47 0)))
             \dir-column \center-align {
               \combine #v-markup #f-markup
               #s-markup
             }
             #b-markup
           }
           \hspace
           #(cond
             ((= 3 (length o-markup)) 0.05)
             ((= 0 (length o-markup)) 0)
             (d -0.37)
             (else -0.1))
           \override #(cons 'direction UP)
           \override #(cons 'baseline-skip 1.0)
           \raise #0.2 \dir-column #o-markups
           #kr-markup
         }
       #})))

lyricsToFunctions = \override LyricText.stencil =
#(with-property-set define-scheme-function (grob)(ly:grob?)
   `(analysis harmony functional)
   (grob-interpret-markup grob
     (markup #:function-markup (use-preset) props (ly:grob-property grob 'text))))


function =
#(with-property-set define-scheme-function (code)(string?)
   `(analysis harmony functional)
   #{
     \markup \function-markup #(use-preset) #props #code
   #})
